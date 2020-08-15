#!/bin/sh
ansible-playbook -i inventory --ask-vault-pass bootstrap.yml $@
