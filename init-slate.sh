#!/bin/bash -
#title			:init-slate.sh
#description		:This script processes a swaggerhub swagger.json definition and formats it to a document that can be used as a quick-start for slate docs.
#author			:Rowland O'Connor @ Email Hippo
#date			:20180920
#usage			:./init-slate.sh -k {SwaggerHub API Key} -u {Swagger URL} -r {The https location (including authentication) of the forked slate repo} -l {The URL of the image to use as the company logo in the slate template}
#notes			:1) On make, index.html.md will overwrite the same document in the local copy of the slate repo
#			:2) On make, company logo from AWS S3 will overwrite the slate logo
#=====================================================================================================================================================

# Error options
#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>log.out 2>&1
set -e

# Global variables
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
tmp_file=/tmp/api.json
tmp_index_md_file=/tmp/index.html.md
opts_file=$current_dir/opts.json
tmp_logo=/tmp/logo.png
github_slate_local=~/slate

# Initialize the working folders etc
init(){
	rm -r -f $github_slate_local
}

# Clone the master Github repo
clone_master(){
	clone_origin=$1
	git clone $clone_origin $github_slate_local
       	cd $github_slate_local	
	git config credential.helper store
	cd -
	return 0
}

# Download the logo
download_logo(){
	logo_url=$1
	curl -o $tmp_logo $logo_url
	return 0
}

# Download the swagger definition
download_wadl(){
	api_key=$1
	swagger_url=$2
	curl -H "accept: application/json" -H Authorization:$1 $2?pretty=true>$tmp_file
	return 0	
}

# Process downloaded file and generate markdown
process(){
	widdershins --environment "opts.json" -y $tmp_file -o $tmp_index_md_file markdown
	return 0
}

# Main entry point
main(){
	echo The API key is $API_KEY
	echo The swagger URL is $SWAGGER_URL
	echo The Github repo is $GITHUB_URL

	#set up the local environment
	init

	download_logo $CUSTOM_LOGO_URL
	echo downloaded custom logo from $CUSTOM_LOGO_URL

	clone_master $GITHUB_URL
	echo "cloned master slate database locally.."

	echo "downloaded company logo.."

	download_wadl $API_KEY $SWAGGER_URL
	echo "downloaded Swagger schema locally.."

	process
	echo "processed local schema file.."

	cp -f $tmp_index_md_file $github_slate_local/source/index.html.md
	echo "published file locally to ~/slate/source/index.html.md"

	cp -f $tmp_logo $github_slate_local/source/images/logo.png
	echo "copied company logo into ~/slate/source/images/logo.png"

	cd $github_slate_local

	git config --global user.email "bot.deploy@emailhippo.com"
	git config --global user.name "Build engine bot"

	git commit -a -m"Generating customised indes.html.md and company logo."
	echo "committed changes to GitHub.."

	git push
	echo "pushed changes to remote.."

	cd -

	return 0
}

# Assign parameters
while getopts k:u:r:l: option
do
case "${option}"
in
k) API_KEY=${OPTARG};;
u) SWAGGER_URL=${OPTARG};;
r) GITHUB_URL=${OPTARG};;
l) CUSTOM_LOGO_URL=${OPTARG};;
esac
done

# Execute
main

