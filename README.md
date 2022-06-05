# krang404_microservices

################################
# Home Work № 12
################################

In Home Work number 12 was created image for build Docker-container with
application "reddit" and next this image pushed on Docker Hub named
"krang404/otus-reddit" taged '1.0'.

Moreover was created code-infrastructure to getting up VM with run
Docker-container application "reddit". All code put in '/infra' folder:
Terraform file and Ansible playbooks. Also it has a Packer-file for create image
with bake-strategy.

################################
# Home Work № 13
################################

In Home Work number 13 application "reddit" was devided to three part and next
moved it to images for Docker-containers. Moreover was created some variants of
images that had differnt size.

###############################
# Home Work # 14
###############################

In this home work was created project with Docker Compose. Also file 'docker-compose.yml' has a variables what was define in '.env'. Moreover a project name defined in variable 'COMPOSE_PROJECT_NAME'.

File 'docker-compose.override.yml' has a overriding parameters of the containers what was configured in main docker-compose file. In this project overriding a volumes and cmd-command.
