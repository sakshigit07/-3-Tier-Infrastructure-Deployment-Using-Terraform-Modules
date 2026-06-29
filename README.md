# Title: 3-Tier Infrastructure Deployment Using Terraform Modules

## **Objective:**

Design and deploy a complete 3-tier web application architecture on AWS using
Terraform modules and automation tools like Ansible or Terraform provisioners.
Project Requirements:
 

## PREREQUISITES

Before running this pipeline make sure that following environments matches the criteria.

- **Ansible Instance:** There must be one ansible instance with ansible installed on it to reach out target servers.
- **Terraform CLI:**  Install Terraform CLI on your local machine to deploy.
- **Code:** Ensure your application code is tested and  ready to deploy.
- **IAM Role:** Create an AWS IAM role with administrationaccess for terraform.
- **S3 Bucket:** Create S3 bucket for state lock file. Named as `cloudstudent-terraform-state-bucket`
- **DynamoDB:** Create DynamoDB table named as `cloudstudent-terraform-locks` with a primary partition key named `LockID` to handle state locking.

## STEPS TO DEPLOY

Follow the sequence to build CI/CD and deploy code.

#### 1. Open VS Code & Copy paste all the code as per tree structure.

```bash
Project 3
│   .gitignore
│   form.sql
│   index.html
│   project3.drawio
│   submit.php
│   
├───ansible
│       ansible.cfg
│       nginx-app.conf.j2
│       nginx-web.conf.j2
│       secret_vars.yml
│       web-app-setup.yml
│       
└───terraform
    │   inventory.ini
    │   main.tf
    │   outputs.tf
    │   variables.tf
    │                               
    └───module
        ├───ec2
        │       main.tf
        │       outputs.tf
        │       variables.tf
        │       
        ├───rds
        │       main.tf
        │       outputs.tf
        │       variables.tf
        │       
        └───vpc
                main.tf
                outputs.tf
                variables.tf
```

#### 2. Open git bash and run following commands:

- Initialize Terraform

```bash
terraform init
```

- View blueprint of structure

```bash
terraform plan
```

- To build real infrastructure.

```bash
terrafrom apply --auto-approve
```

- Update `inventory.ini` file in ansible server.
- Execute ansible playbook command:

```bash
ansible playbook -i inventory.ini web-app-setup.yml
```

- Copy the public IP address of your web server and open it in a browser.

## How the system works

The application follows a **3-tier architecture**, where every request passes through three layers in order:

```bash
		Web Tier -> App tier -> Database Tier
```

Each tier have their own responsibility and communicates with each other.

WORKFLOW

```bash
User Browser -> Web server(nginx) -> App server(php-fpm) -> RDS Database(MySQL)
```

1. **Web server (Public Subnet)**
    - The user opens the website in their browser.
    - The request reaches the **Web Server**, which is in the **public subnet**.
    - If the request is for a PHP page (such as `submit.php`), it forwards the request to the **App Server** using **Nginx reverse proxy**.
2. **App server (Private Subnet)** 
    - The **App Server** is in a **private subnet**, so it cannot be accessed directly from the internet.
    - It only accepts requests coming from the Web Server.
    - Nginx on the App Server passes the PHP request to **PHP-FPM**.
    - PHP-FPM executes the PHP code, processes the form data, and prepares the database query.
3. **RDS Database (MySQL)**
    - The processed data is sent to **AWS RDS MySQL**.
    - The RDS database is also in a **private subnet**.
    - It only allows connections on **Port 3306** from the **Application Server's Security Group**.
    - The database stores the student information securely.

### Screenshots of outputs and infrastructure

- Outputs

![alt text](images/Screenshot(299).png)

- RDS created by Terraform

![alt text](images/Screenshot(298).png)     

- VPC created by Terraform

![alt text](images/Screenshot(297).png)

- 5 server : 2 servers of web , 2 servers of app and 1 ansible server

![alt text](images/Screenshot(296).png)  

Sample app: 

![alt text](images/Screenshot(295).png)

![alt text](images/Screenshot(294).png)

---

## Tear down the infrastructure

To avoid unnecessary charges by AWS, simply run the following command :

```bash
terraform destroy --auto-approve
```

This command will terminate the whole infrastructure created by **Terraform** only**.**