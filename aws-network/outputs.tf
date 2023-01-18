output "vpc_id" {
  value = aws_vpc.main-vpc.id
}


output "vpc_cidr" {
  value = aws_vpc.main-vpc.cidr_block
}


output "public_subnets_ids" {
  value = aws_subnet.public-subnets[*].id
}


output "private_subnets_ids" {
  value = aws_subnet.private-subnets[*].id
}
