provider "aws" {
  region = "il-central-1"  
}

resource "aws_instance" "jenkins" {
  ami           = "ami-0d5eff06f840b45e9"  # Ubuntu 22.04 AMI ID (update with the latest AMI ID)
  instance_type = "t2.micro"
  key_name      = "roee-aws1" 

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
              EOF
}

resource "aws_instance" "my_ubuntu" {
  ami           = "ami-0d5eff06f840b45e9"  # Ubuntu 22.04 AMI ID (update with the latest AMI ID)
  instance_type = "t2.micro"
  key_name      = "roee-aws1"  

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
              EOF
}

resource "aws_instance" "my_windows" {
  ami           = "ami-0c3f0ddf05e0e4e67"  # Windows AMI ID (update with the latest AMI ID)
  instance_type = "t2.micro"
  key_name      = "roee-aws1"  

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
              </powershell>
              EOF
}
