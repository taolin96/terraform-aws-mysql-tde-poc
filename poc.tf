terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "taolin"

    workspaces {
      name = "terraform-aws-mysql-tde-poc"
    }
  }
}

provider "aws" {
  profile 	= var.AWS_PROFILE
  region 	= "ap-southeast-2"
}

resource "aws_iam_user" "npfdrdb" {
  name 	= "npfdrdb"
  tags 	= {
    Terraform 	= "Yes"
  }
}

resource "aws_iam_access_key" "npfdrdb" {
  user 	= aws_iam_user.npfdrdb.name
}

data "aws_iam_policy_document" "kms-key-admin" {
  statement {
    sid 	= "Enable IAM User Permissions"
    effect 	= "Allow"
    actions 	= ["kms:*"]
    resources 	= ["*"]
    principals  {
      type 	  = "AWS"
      identifiers = ["arn:aws:iam::925521465328:root"]
    }
  }

  statement {
    sid 	= "Enable kms key admin Permissions"
    effect 	= "Allow"
    actions 	= ["kms:*"] 
    resources 	= ["*"]
    principals 	{
      type        = "AWS"
      identifiers = [aws_iam_user.npfdrdb.arn]
    }
  }
}

resource "aws_kms_key" "poc-tde-mysql" {
  description 		  = "MySQL TDE POC - JL"
  deletion_window_in_days = "10"
  enable_key_rotation 	  = "true"
  tags 			  = { Terraform = "Yes" }
  policy 		  = data.aws_iam_policy_document.kms-key-admin.json
}

resource "aws_kms_alias" "poc-mysql-tde" {
  name 		= "alias/poc-mysql-tde"
  target_key_id = aws_kms_key.poc-tde-mysql.key_id
}
