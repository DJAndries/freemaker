#!/bin/sh
ansible-playbook -i inventory --ask-vault site.yml $@
