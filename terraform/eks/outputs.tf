# Output the public IP for SSH access
output "ssh_connection_string_master" {
  value = "ssh ubuntu@${aws_instance.jenkins_master.public_ip}"
}

output "ssh_connection_string_slave" {
  value = "ssh ubuntu@${aws_instance.jenkins_slave.public_ip}"
}