output "webserver_public_ip"{
	value = aws_instance.web-server.public_ip
}

output "webserver_id"{
	value = aws_instance.web-server.id
}