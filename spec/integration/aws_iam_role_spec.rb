require 'spec_helper'
require 'securerandom'

def mk_role_name
  name_postfix = SecureRandom.hex(8)
  "chef_provisioning_test_iam_role_#{name_postfix}"
end

def ec2_role_policy
<<EOF
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
end

describe Chef::Resource::AwsIamRole do
  extend AWSSupport

  when_the_chef_12_server "exists", organization: "foo", server_scope: :context do
    with_aws "when connected to AWS" do

      context "Basic IAM role creation" do
        role_name = mk_role_name

        it "aws_iam_role '#{role_name}' creates an IAM role" do

          expect_recipe {
            aws_iam_role role_name do
              assume_role_policy_document ec2_role_policy
            end
          }.to create_an_aws_iam_role(role_name).and be_idempotent
        end

      end

      context "create role with instance profile" do
        role_name = mk_role_name

        it "aws_iam_instance_profile '#{role_name}' creates an instance profile with role" do
          expect_recipe {

            aws_iam_role role_name do
              assume_role_policy_document ec2_role_policy
            end

            aws_iam_instance_profile role_name do
              role role_name
            end

          }.to create_an_aws_iam_role(role_name).and be_idempotent

          role = driver.iam_resource.role(role_name)

          expect(role.instance_profiles.count).to eq 1
          expect(role.instance_profiles.first.name).to eq(role_name)
        end
      end

    end

  end
end
