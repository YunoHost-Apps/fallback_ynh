#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# dependencies used by the app
pkg_dependencies="ccrypt rsync mlocate"

#=================================================
# PACKAGE CHECK BYPASSING...
#=================================================

IS_PACKAGE_CHECK () {
	if [ ${PACKAGE_CHECK_EXEC:-0} -eq 1 ]
	then
		return 0
	else
		return 1
	fi
}

#=================================================
# FUTUR OFFICIAL HELPERS
#=================================================


#=================================================
# EXPERIMENTAL HELPERS
#=================================================

# Send an email to inform the administrator
#
# usage: ynh_send_readme_to_admin --app_message=app_message [--recipients=recipients] [--type=type]
# | arg: -m --app_message= - The file with the content to send to the administrator.
# | arg: -r, --recipients= - The recipients of this email. Use spaces to separate multiples recipients. - default: root
#	example: "root admin@domain"
#	If you give the name of a YunoHost user, ynh_send_readme_to_admin will find its email adress for you
#	example: "root admin@domain user1 user2"
# | arg: -t, --type= - Type of mail, could be 'backup', 'change_url', 'install', 'remove', 'restore', 'upgrade'
ynh_send_readme_to_admin() {
	# Declare an array to define the options of this helper.
	declare -Ar args_array=( [m]=app_message= [r]=recipients= [t]=type= )
	local app_message
	local recipients
	local type
	# Manage arguments with getopts

	ynh_handle_getopts_args "$@"
	app_message="${app_message:-}"
	recipients="${recipients:-root}"
	type="${type:-install}"

	# Get the value of admin_mail_html
	admin_mail_html=$(ynh_app_setting_get $app admin_mail_html)
	admin_mail_html="${admin_mail_html:-0}"

	# Retrieve the email of users
	find_mails () {
		local list_mails="$1"
		local mail
		local recipients=" "
		# Read each mail in argument
		for mail in $list_mails
		do
			# Keep root or a real email address as it is
			if [ "$mail" = "root" ] || echo "$mail" | grep --quiet "@"
			then
				recipients="$recipients $mail"
			else
				# But replace an user name without a domain after by its email
				if mail=$(ynh_user_get_info "$mail" "mail" 2> /dev/null)
				then
					recipients="$recipients $mail"
				fi
			fi
		done
		echo "$recipients"
	}
	recipients=$(find_mails "$recipients")

	# Subject base
	local mail_subject="☁️🆈🅽🅷☁️: \`$app\`"

	# Adapt the subject according to the type of mail required.
	if [ "$type" = "backup" ]; then
		mail_subject="$mail_subject has just been backup."
	elif [ "$type" = "change_url" ]; then
		mail_subject="$mail_subject has just been moved to a new URL!"
	elif [ "$type" = "remove" ]; then
		mail_subject="$mail_subject has just been removed!"
	elif [ "$type" = "restore" ]; then
		mail_subject="$mail_subject has just been restored!"
	elif [ "$type" = "upgrade" ]; then
		mail_subject="$mail_subject has just been upgraded!"
	else	# install
		mail_subject="$mail_subject has just been installed!"
	fi

	local mail_message="This is an automated message from your beloved YunoHost server.

Specific information for the application $app.

$(if [ -n "$app_message" ]
then
	cat "$app_message"
else
	echo "...No specific information..."
fi)

---
Automatic diagnosis data from YunoHost

__PRE_TAG1__$(yunohost tools diagnosis | grep -B 100 "services:" | sed '/services:/d')__PRE_TAG2__"

	# Store the message into a file for further modifications.
	echo "$mail_message" > mail_to_send

	# If a html email is required. Apply html tags to the message.
 	if [ "$admin_mail_html" -eq 1 ]
 	then
		# Insert 'br' tags at each ending of lines.
		ynh_replace_string "$" "<br>" mail_to_send

		# Insert starting HTML tags
		sed --in-place '1s@^@<!DOCTYPE html>\n<html>\n<head></head>\n<body>\n@' mail_to_send

		# Keep tabulations
		ynh_replace_string "  " "\&#160;\&#160;" mail_to_send
		ynh_replace_string "\t" "\&#160;\&#160;" mail_to_send

		# Insert url links tags
		ynh_replace_string "__URL_TAG1__\(.*\)__URL_TAG2__\(.*\)__URL_TAG3__" "<a href=\"\2\">\1</a>" mail_to_send

		# Insert pre tags
		ynh_replace_string "__PRE_TAG1__" "<pre>" mail_to_send
		ynh_replace_string "__PRE_TAG2__" "<\pre>" mail_to_send

		# Insert finishing HTML tags
		echo -e "\n</body>\n</html>" >> mail_to_send

	# Otherwise, remove tags to keep a plain text.
	else
		# Remove URL tags
		ynh_replace_string "__URL_TAG[1,3]__" "" mail_to_send
		ynh_replace_string "__URL_TAG2__" ": " mail_to_send

		# Remove PRE tags
		ynh_replace_string "__PRE_TAG[1-2]__" "" mail_to_send
	fi

	# Define binary to use for mail command
	if [ -e /usr/bin/bsd-mailx ]
	then
		local mail_bin=/usr/bin/bsd-mailx
	else
		local mail_bin=/usr/bin/mail.mailutils
	fi

	if [ "$admin_mail_html" -eq 1 ]
	then
		content_type="text/html"
	else
		content_type="text/plain"
	fi

	# Send the email to the recipients
	cat mail_to_send | $mail_bin -a "Content-Type: $content_type; charset=UTF-8" -s "$mail_subject" "$recipients"
}

#=================================================

ynh_maintenance_mode_ON () {
	# Load value of $path_url and $domain from the config if their not set
	if [ -z $path_url ]; then
		path_url=$(ynh_app_setting_get $app path)
	fi
	if [ -z $domain ]; then
		domain=$(ynh_app_setting_get $app domain)
	fi

	mkdir -p /var/www/html/
	
	# Create an html to serve as maintenance notice
	echo "<!DOCTYPE html>
<html>
<head>
<meta http-equiv="refresh" content="3">
<title>Your app $app is currently under maintenance!</title>
<style>
	body {
		width: 70em;
		margin: 0 auto;
	}
</style>
</head>
<body>
<h1>Your app $app is currently under maintenance!</h1>
<p>This app has been put under maintenance by your administrator at $(date)</p>
<p>Please wait until the maintenance operation is done. This page will be reloaded as soon as your app will be back.</p>

</body>
</html>" > "/var/www/html/maintenance.$app.html"

	# Create a new nginx config file to redirect all access to the app to the maintenance notice instead.
	echo "# All request to the app will be redirected to ${path_url}_maintenance and fall on the maintenance notice
rewrite ^${path_url}/(.*)$ ${path_url}_maintenance/? redirect;
# Use another location, to not be in conflict with the original config file
location ${path_url}_maintenance/ {
alias /var/www/html/ ;

try_files maintenance.$app.html =503;

# Include SSOWAT user panel.
include conf.d/yunohost_panel.conf.inc;
}" > "/etc/nginx/conf.d/$domain.d/maintenance.$app.conf"

	# The current config file will redirect all requests to the root of the app.
	# To keep the full path, we can use the following rewrite rule:
	# 	rewrite ^${path_url}/(.*)$ ${path_url}_maintenance/\$1? redirect;
	# The difference will be in the $1 at the end, which keep the following queries.
	# But, if it works perfectly for a html request, there's an issue with any php files.
	# This files are treated as simple files, and will be downloaded by the browser.
	# Would be really be nice to be able to fix that issue. So that, when the page is reloaded after the maintenance, the user will be redirected to the real page he was.

	systemctl reload nginx
}

ynh_maintenance_mode_OFF () {
	# Load value of $path_url and $domain from the config if their not set
	if [ -z $path_url ]; then
		path_url=$(ynh_app_setting_get $app path)
	fi
	if [ -z $domain ]; then
		domain=$(ynh_app_setting_get $app domain)
	fi

	# Rewrite the nginx config file to redirect from ${path_url}_maintenance to the real url of the app.
	echo "rewrite ^${path_url}_maintenance/(.*)$ ${path_url}/\$1 redirect;" > "/etc/nginx/conf.d/$domain.d/maintenance.$app.conf"
	systemctl reload nginx

	# Sleep 4 seconds to let the browser reload the pages and redirect the user to the app.
	sleep 4

	# Then remove the temporary files used for the maintenance.
	rm "/var/www/html/maintenance.$app.html"
	rm "/etc/nginx/conf.d/$domain.d/maintenance.$app.conf"

	systemctl reload nginx
}

#=================================================

# Create a changelog for an app after an upgrade.
#
# The changelog is printed into the file ./changelog for the time of the upgrade.
#
# In order to create a changelog, ynh_app_changelog will get info from /etc/yunohost/apps/$app/status.json
# In order to find the current commit use by the app.
# The remote repository, and the branch.
# The changelog will be only the commits since the current revision.
#
# Because of the need of those info, ynh_app_changelog works only
# with apps that have been installed from a list.
#
# usage: ynh_app_changelog
ynh_app_changelog () {
	get_value_from_settings ()
	{
		local value="$1"
		# Extract a value from the status.json file of an installed app.

		grep "$value\": \"" /etc/yunohost/apps/$app/status.json | sed "s/.*$value\": \"\([^\"]*\).*/\1/"
	}

	local current_revision="$(get_value_from_settings revision)"
	local repo="$(get_value_from_settings url)"
	local branch="$(get_value_from_settings branch)"
	# ynh_app_changelog works only with an app installed from a list.
	if [ -z "$current_revision" ] || [ -z "$repo" ] || [ -z "$branch" ]
	then
		ynh_print_warn "Unable to build the changelog..."
		touch changelog
		return 0
	fi

	# Fetch the history of the repository, without cloning it
	mkdir git_history
	(cd git_history
	ynh_exec_warn_less git init
	ynh_exec_warn_less git remote add -f origin $repo
	# Get the line of the current commit of the installed app in the history.
	local line_to_head=$(git log origin/$branch --pretty=oneline | grep --line-number "$current_revision" | cut -d':' -f1)
	# Cut the history before the current commit, to keep only newer commits.
	# Then use sed to reorganise each lines and have a nice list of commits since the last upgrade.
	# This list is redirected into the file changelog
	git log origin/$branch --pretty=oneline | head --lines=$(($line_to_head-1)) | sed 's/^\([[:alnum:]]*\)\(.*\)/*(\1) -> \2/g' > ../changelog)
	# Remove 'Merge pull request' commits
	sed -i '/Merge pull request #[[:digit:]]* from/d' changelog
	# As well as conflict resolving commits
	sed -i '/Merge branch .* into/d' changelog

	# Get the value of admin_mail_html
	admin_mail_html=$(ynh_app_setting_get $app admin_mail_html)
	admin_mail_html="${admin_mail_html:-0}"

	# If a html email is required. Apply html to the changelog.
 	if [ "$admin_mail_html" -eq 1 ]
 	then
		sed -in-place "s@\*(\([[:alnum:]]*\)) -> \(.*\)@* __URL_TAG1__\2__URL_TAG2__${repo}/commit/\1__URL_TAG3__@g" changelog
 	fi
}

#=================================================

# Check the amount of available RAM
#
# usage: ynh_check_ram [--required=RAM required in Mb] [--no_swap|--only_swap] [--free_ram]
# | arg: -r, --required= - Amount of RAM required in Mb. The helper will return 0 is there's enough RAM, or 1 otherwise.
# If --required isn't set, the helper will print the amount of RAM, in Mb.
# | arg: -s, --no_swap   - Ignore swap
# | arg: -o, --only_swap - Ignore real RAM, consider only swap.
# | arg: -f, --free_ram  - Count only free RAM, not the total amount of RAM available.
ynh_check_ram () {
	# Declare an array to define the options of this helper.
	declare -Ar args_array=( [r]=required= [s]=no_swap [o]=only_swap [f]=free_ram )
	local required
	local no_swap
	local only_swap
	# Manage arguments with getopts
	ynh_handle_getopts_args "$@"
	required=${required:-}
	no_swap=${no_swap:-0}
	only_swap=${only_swap:-0}

	local total_ram=$(vmstat --stats --unit M | grep "total memory" | awk '{print $1}')
	local total_swap=$(vmstat --stats --unit M | grep "total swap" | awk '{print $1}')
	local total_ram_swap=$(( total_ram + total_swap ))

	local free_ram=$(vmstat --stats --unit M | grep "free memory" | awk '{print $1}')
	local free_swap=$(vmstat --stats --unit M | grep "free swap" | awk '{print $1}')
	local free_ram_swap=$(( free_ram + free_swap ))

	# Use the total amount of ram
	local ram=$total_ram_swap
	if [ $free_ram -eq 1 ]
	then
		# Use the total amount of free ram
		ram=$free_ram_swap
		if [ $no_swap -eq 1 ]
		then
			# Use only the amount of free ram
			ram=$free_ram
		elif [ $only_swap -eq 1 ]
		then
			# Use only the amount of free swap
			ram=$free_swap
		fi
	else
		if [ $no_swap -eq 1 ]
		then
			# Use only the amount of free ram
			ram=$total_ram
		elif [ $only_swap -eq 1 ]
		then
			# Use only the amount of free swap
			ram=$total_swap
		fi
	fi

	if [ -n "$required" ]
	then
		# Return 1 if the amount of ram isn't enough.
		if [ $ram -lt $required ]
		then
			return 1
		else
			return 0
		fi

	# If no RAM is required, return the amount of available ram.
	else
		echo $ram
	fi
}
