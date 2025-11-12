


data "aws_availability_zones" "available"{}

#--------vpc and internet-gateway-------------------

resource "aws_vpc" "main_vpc"{
	cidr_block = var.vpc_cidr

	tags = {
		name = "${var.env}-vpc"
	}
}


resource "aws_internet_gateway" "main"{
	vpc_id = aws_vpc.main_vpc.id
}

#------------public subnet and route_table-----------------------

resource "aws_subnet" "public_subnet"{
	count = length(var.public_subnet_cidr)
	vpc_id = aws_vpc.main_vpc.id
	cidr_block = element(var.public_subnet_cidr, count.index)
	availability_zone = data.aws_availability_zones.available.names[count.index]
	map_public_ip_on_launch = true # maps an ip address to your runnuing instance
	tags = merge(var.tags, {name = "${var.env}-public-${count.index +1}"})
}

resource "aws_route_table" "public_subnet"{
	vpc_id = aws_vpc.main_vpc.id
	route{
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.main.id
	}
}

resource "aws_route_table_association" "public_route"{
	count = length(aws_subnet.public_subnet[*].id)
	route_table_id = aws_route_table.public_subnet.id
	subnet_id = aws_subnet.public_subnet[count.index].id

}


#--------------NAT gateway and Elastic-ip -----------------------------

resource "aws_eip" "nat" {
	count = length(var.private_subnet_cidr)
	domain = "vpc"
	tags   = merge(var.tags, { Name = "${var.env}-nat-gw-${count.index + 1}" })

}

resource "aws_nat_gateway" "nat"{
	count = length(var.private_subnet_cidr)
	allocation_id = aws_eip.nat[count.index].id
	subnet_id = aws_subnet.public_subnet[count.index].id
	tags          = merge(var.tags, { Name = "${var.env}-nat-gw-${count.index + 1}" })
}

resource "aws_subnet" "private_subnet"{
	count = length(var.private_subnet_cidr)
	vpc_id = aws_vpc.main_vpc.id
	cidr_block = element(var.private_subnet_cidr, count.index)
	availability_zone = data.aws_availability_zones.available.names[count.index]
	tags = merge(var.tags, {name = "${var.env}-private-{${count.index + 1}"})
}

resource "aws_route_table" "private_subnet"{
	count = length(var.private_subnet_cidr)
	vpc_id = aws_vpc.main_vpc.id 
	route{
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.nat[count.index].id
	}
}

resource "aws_route_table_association" "private_route"{
	count = length(aws_subnet.private_subnet[*].id)
	route_table_id = aws_route_table.private_subnet[count.index].id
	subnet_id = aws_subnet.private_subnet[count.index].id
}
