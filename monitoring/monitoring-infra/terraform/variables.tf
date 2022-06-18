variable "cloud_id" {
  description = "Cloud"
  type        = string
  default     = "b1g23e813tdf5mi1dlqg"
}
variable "folder_id" {
  description = "Folder"
  type        = string
  default     = "b1g3ev1fmlsskdbgvue4"
}
#variable "ya_auth_token" {
#  description = "ya_auth_token"
#  type        = string
#}
variable "zone" {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable "public_key_path" {
  # Описание переменной
  description = "Path to the public key used for ssh access"
  default     = "~/.ssh/yc.pub"
}
variable "private_key_path" {
  description = "Path to the private key used for ssh access"
  default     = "~/.ssh/yc"
}
variable "image_id" {
  description = "Disk image"
  type        = string
  default     = "fd8hjvnsltkcdeqjom1n"
}
variable "subnet_id" {
  description = "Subnet"
  type        = string
  default     = "e9bgn0tovipqf79pnaf4"
}
variable "service_account_key_file" {
  description = "key.json"
  default     = "/home/nik/Otus/GitHub-lab/key.json"
}
variable "instance_count" {
  description = "count var"
  default     = "1"
}
