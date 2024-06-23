
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

# Create S3 Bucket
resource "aws_s3_bucket" "instance_data_bucket" {
  bucket = "mydatabucket222"
  
  tags = {
    Name = "InstanceDataBucket"
  }
}

#Set S3 Bucket ACL 
resource "aws_s3_bucket_acl" "instance_data_bucket_acl" {
  bucket = aws_s3_bucket.instance_data_bucket.id
  acl = "private"
}

# IAM Role and Policy for EC2 instances to access S3
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
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
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
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
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Jenkins Instance
resource "aws_instance" "jenkins" {
  ami                      = "ami-0d5eff06f840b45e9"
  instance_type            = "t2.micro"
  key_name                 = "roee-aws1"
  iam_instance_profile     = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "Jenkins"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y openjdk-11-jdk
              sudo apt-get install -y git
              wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
              sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              sudo apt-get update
              sudo apt-get install -y jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              sudo apt-get install -y awscli
              aws s3 cp /path/to/data s3://${aws_s3_bucket.instance_data_bucket.bucket}/jenkins/ --recursive
              EOF
}

# Ubuntu Instance
resource "aws_instance" "my_ubuntu" {
  ami                      = "ami-0d5eff06f840b45e9"
  instance_type            = "t2.micro"
  key_name                 = "roee-aws1"
  iam_instance_profile     = aws_iam_instance_profile.ec2_instance_profile.name

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
              aws s3 cp /path/to/data s3://${aws_s3_bucket.instance_data_bucket.bucket}/ubuntu/ --recursive
              EOF
}

# Windows Instance
resource "aws_instance" "my_windows" {
  ami                      = "ami-0c3f0ddf05e0e4e67"
  instance_type            = "t2.micro"
  key_name                 = "roee-aws1"
  iam_instance_profile     = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "My-Windows"
  }

  user_data = <<-EOF
              <powershell>
              Install-WindowsFeature -Name Web-Server -IncludeManagementTools
              Invoke-WebRequest -Uri "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip" -OutFile "C:\jdk-17_windows-x64_bin.zip"
              Expand-Archive -Path "C:\jdk-17_windows-x64_bin.zip" -DestinationPath "C:\Java"
              [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Java\jdk-17", "Machine")
              [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Java\jdk-17\bin", "Machine")

              Invoke-WebRequest -Uri "https://download.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -OutFile "C:\DockerDesktopInstaller.exe"
              Start-Process -FilePath "C:\DockerDesktopInstaller.exe" -ArgumentList "install" -NoNewWindow -Wait

              Start-Sleep -Seconds 15

              Start-Process -FilePath "C:\Program Files\Docker\Docker\DockerCli.exe" -ArgumentList "-SwitchDaemon" -NoNewWindow -Wait
              
              Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\AWSCLIV2.msi"
              Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\AWSCLIV2.msi /quiet" -Wait
              aws s3 cp C:\path\to\data s3://${aws_s3_bucket.instance_data_bucket.bucket}/windows/ --recursive
              </powershell>
              EOF
}
