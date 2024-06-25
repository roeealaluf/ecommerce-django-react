terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.53.0"
    }
  }
}

provider "aws" {
  region = "il-central-1" 
}


resource "aws_s3_bucket" "instance_data_bucket" {
  bucket = "mydatabucket223"
  
  tags = {
    Name = "InstanceDataBucket"
  }

  lifecycle {
    ignore_changes = [bucket]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Security group for EC2 instances"

  ingress {
    from_port   = 22 
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 8080  
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  ingress {
    from_port   = 3306  
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Instance Security Group"
  }
}


resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_role.id

  policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ],
          "Resource": "arn:aws:s3:::${aws_s3_bucket.instance_data_bucket.bucket}/*"
        }
      ]
    }
  EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}


# MySQL Instance
resource "aws_instance" "mysql" {
  ami                   = "ami-07c0a4909b86650c0" 
  instance_type         = "t3.micro"
  key_name              = "aws-roee1"
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups       = [aws_security_group.instance_sg.name]

  tags = {
    Name = "MySQL"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y mysql-server
              sudo systemctl start mysql
              sudo systemctl enable mysql
              sudo mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'your_password';"
              sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;"
              sudo mysql -e "FLUSH PRIVILEGES;"
              sudo mysql -e "CREATE DATABASE my_database;"
              sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
              sudo systemctl restart mysql
              sudo apt-get install -y awscli

              # Create backup script 
              cat << 'EOB' > /home/ubuntu/backup.sh
              #!/bin/bash
              DB_NAME="my_database"
              DB_USER="admin"
              DB_PASS="your_password"
              BUCKET_NAME="mydatabucket223"
              BACKUP_PATH="/backup"
              TIMESTAMP=$(date +"%F")
              BACKUP_FILE="$BACKUP_PATH/$DB_NAME-$TIMESTAMP.sql"
              
              mkdir -p $BACKUP_PATH
              mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_FILE
              aws s3 cp $BACKUP_FILE s3://$BUCKET_NAME/mysql-backups/
              rm -f $BACKUP_FILE
              EOB
              
              chmod +x /home/ubuntu/backup.sh
              
              # Create cron job for daily backups at 2am
              (crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/backup.sh") | crontab -
              EOF
}


# Jenkins Instance
resource "aws_instance" "jenkins" {
  ami                   = "ami-07c0a4909b86650c0"
  instance_type         = "t3.micro"
  key_name              = "aws-roee1"
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups       = [aws_security_group.instance_sg.name]

  tags = {
    Name = "Jenkins"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y openjdk-17-jdk
              sudo apt-get install -y git
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
              /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
              https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
              /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              sudo apt-get update
              sudo apt-get install -y jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              sudo apt-get install -y awscli
              sudo apt-get install -y mysql-client
              mysql -u admin -p'your_password' -h ${aws_instance.mysql.public_ip} -e "CREATE DATABASE jenkins;"
              aws s3 cp . s3://${aws_s3_bucket.instance_data_bucket.bucket}/jenkins/ --recursive
              EOF
}

# Ubuntu Instance
resource "aws_instance" "my_ubuntu" {
  ami                   = "ami-07c0a4909b86650c0"
  instance_type         = "t3.micro"
  key_name              = "aws-roee1"
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups       = [aws_security_group.instance_sg.name]

  tags = {
    Name = "My-Ubuntu"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y openjdk-11-jdk
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo apt-get install -y awscli
              sudo apt-get install -y mysql-client
              mysql -u admin -p'your_password' -h ${aws_instance.mysql.public_ip} -e "CREATE DATABASE jenkins;"
              aws s3 cp . s3://${aws_s3_bucket.instance_data_bucket.bucket}/ubuntu/ --recursive
              EOF
}

# Windows Instance
resource "aws_instance" "my_windows" {
  ami                   = "ami-07df29cf3e326c3ad"
  instance_type         = "t3.micro"
  key_name              = "aws-roee2"
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups       = [aws_security_group.instance_sg.name]

  tags = {
    Name = "My-Windows"
  }

  user_data = <<-EOF
              <powershell>
              Install-WindowsFeature -Name Web-Server -IncludeManagementTools
              Invoke-WebRequest -Uri "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip" -OutFile "C:\\jdk-17_windows-x64_bin.zip"
              Expand-Archive -Path "C:\\jdk-17_windows-x64_bin.zip" -DestinationPath "C:\\Java"
              [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\\Java\\jdk-17", "Machine")
              [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\\Java\\jdk-17\\bin", "Machine")

              Invoke-WebRequest -Uri "https://download.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile "C:\\DockerDesktopInstaller.exe"
              Start-Process -FilePath "C:\\DockerDesktopInstaller.exe" -ArgumentList "install" -NoNewWindow -Wait

              Start-Sleep -Seconds 15

              Start-Process -FilePath "C:\\Program Files\\Docker\\Docker\\DockerCli.exe" -ArgumentList "-SwitchDaemon" -NoNewWindow -Wait
              
              Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\\AWSCLIV2.msi"
              Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\\AWSCLIV2.msi /quiet" -Wait
              sudo apt-get install -y mysql-client
              mysql -u admin -p'your_password' -h ${aws_instance.mysql.public_ip} -e "CREATE DATABASE jenkins;"
              aws s3 cp . s3://${aws_s3_bucket.instance_data_bucket.bucket}/ubuntu/ --recursive
              </powershell>
              
              EOF
}