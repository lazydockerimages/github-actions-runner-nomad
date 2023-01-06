# Github Actions Runner Nomad

This repo builds a docker image that contains the Github actions runner based on Ubuntu. It also packages Hashicorp's Nomad so that it can be used to deploy nomad jobs from Github Actions.

Note that Github Actions Runner tokens expire after one hour, so you will have to obtain new tokens when necessary (ie during initial setup and testing), and tidy up any offline runners.
