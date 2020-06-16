provider "aws" {
  region  = "ap-south-1"
  profile = "upam"
}

resource "aws_security_group" "secgrp" {
  name        = "secgrp"
  description = "Allow SSH and HTTP"
  vpc_id      = "vpc-a5e2ffcd"

  ingress {
    description = "SSH"
    from_port   = 22	
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80	
    to_port     = 80
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
    Name = "secgrp"
  }
}
resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name      = "key111"
  security_groups = ["secgrp"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/ANJALI RAY/Downloads/key111.pem")
    host     = aws_instance.web.public_ip
  }
  

 provisioner "remote-exec" {

    inline = [
      "sudo yum install php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd", 
      
    ]
  }
 tags = {
    Name = "lwos1"
  }
}

resource "aws_ebs_volume" "esb1" {
  availability_zone =aws_instance.web.availability_zone 
  size              = 1

  tags = {
    Name = "lwebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.esb1.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}

output"myos_ip"{
   value = aws_instance.web.public_ip
}

resource "null_resource""nulllocal2"{
    provisioner "local-exec" {
       command="echo ${aws_instance.web.public_ip} > publicip.txt"
  }
}


resource "null_resource" "nullremote3"{

depends_on = [
    aws_volume_attachment.ebs_att
  ]  
   connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/ANJALI RAY/Downloads/key111.pem")
    host     = aws_instance.web.public_ip
  }
provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh", 
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/rayanjali/hybridcloud.git /var/www/html/"
    ]
  }
}


resource "aws_s3_bucket" "terrabucketan" {
  
  bucket = "somethingan"
  acl    = "public-read"
   versioning {
    enabled = true
  }
  tags = {
    Name        = "fighttera"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_object" "object" {
  depends_on = [
  aws_s3_bucket.terrabucketan
  ]

  bucket = "somethingan"
  key    = "pic.jpg"
  source = "C:/Users/ANJALI RAY/Downloads/pic.jpg"
  content_type="image/jpg"
  acl    = "public-read"
  
}



output"mybucketdet1"{
   value = aws_s3_bucket.terrabucketan
}

variable "my_id" {
 type = string
 default = "S3-"
}

locals {
 s3_origin_id = "${var.my_id}${aws_s3_bucket.terrabucketan.id}"
}

resource "aws_cloudfront_distribution" "distribution" {
	depends_on = [
  		aws_s3_bucket_object.object,
 	]
 
 	origin {
  		domain_name = "${aws_s3_bucket.terrabucketan.bucket_regional_domain_name}"
  		origin_id = "${local.s3_origin_id}"
 	} 
 
 	enabled = true
 
 	default_cache_behavior {
	 	allowed_methods = [ "GET", "HEAD", "OPTIONS"]
 		cached_methods = ["GET", "HEAD"]
 		target_origin_id = "${local.s3_origin_id}"

		forwarded_values {
  		query_string = false
  
  			cookies {
   			forward = "none"
  			}
 		}
 		viewer_protocol_policy = "allow-all"
 		min_ttl = 0
		default_ttl = 3600
 		max_ttl = 86400
	}

	restrictions {
 		geo_restriction {
  			restriction_type = "none"
 			}
	}

	viewer_certificate {
	cloudfront_default_certificate = true
	}
	connection {
	type = "ssh"
	user = "ec2-user"
	private_key = file("C:/Users/ANJALI RAY/Downloads/key111.pem")
	host = aws_instance.web.public_ip
	}
 
	provisioner "remote-exec"{
 	inline = [
	  	"sudo su <<END",
  	  	"echo \"<img src='http://${aws_cloudfront_distribution.distribution.domain_name}/${aws_s3_bucket_object.object.key}' height='400' width='450'>\" >> /var/www/html/index.php",
  		"END",
 		]
	}
}





resource "null_resource""nulllocal1"{

    depends_on = [
       null_resource.nullremote3
  ]  
    provisioner "local-exec" {
       command="chrome ${aws_instance.web.public_ip}"
  }
}
