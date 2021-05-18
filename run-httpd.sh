#!/bin/bash

if [ -z ${RH_SSO_FQDN} ]; then
	echo "Environment variable RH_SSO_FQDN undefined"
	exit 1
elif [[ -z $CLIENT_ID ]]; then
	echo "Environment variable CLIENT_ID undefined"
	exit 1
elif [[ -z $CLIENT_SECRET ]]; then
	echo "Environment variable CLIENT_SECRET undefined"
	exit 1
elif [[ -z $REVERSE_SSO_ROUTE ]]; then
	echo "Environment variable REVERSE_SSO_ROUTE undefined"
	exit 1
elif [[ -z ${DST_SERVICE_NAME} ]]; then
	echo "Environment variable DST_SERVICE_NAME undefined"
	exit 1
elif [[ -z $RH_SSO_REALM ]]; then
	echo "Environment variable RH_SSO_REALM undefined"
	exit 1
elif [[ -z ${DST_SERVICE_PORT} ]]; then
	echo "Environment variable DST_SERVICE_PORT undefined"
	exit 1
fi

if [[ ${REMOTE_SECURE} -qe "yes" ]]; then
	DST_PROTOCAL="https"
else
	DST_PROTOCAL="http"

echo "
<VirtualHost *:8080>
        RewriteEngine On
        OIDCProviderMetadataURL https://${RH_SSO_FQDN}/auth/realms/${RH_SSO_REALM}/.well-known/openid-configuration
        OIDCClientID $CLIENT_ID
        OIDCClientSecret $CLIENT_SECRET
        OIDCRedirectURI https://${REVERSE_SSO_ROUTE}/oauth2callback
	OIDCCryptoPassphrase openshift

	<Directory "/opt/app-root/">
   		AllowOverride All
	</Directory>

        <Location />
            AuthType openid-connect
    	    Require valid-user
            ProxyPreserveHost on
            ProxyPass	${DST_PROTOCAL}://${DST_SERVICE_NAME}:${DST_SERVICE_PORT}/
	    ProxyPassReverse	${DST_PROTOCAL}://${DST_SERVICE_NAME}:${DST_SERVICE_PORT}/
            RewriteCond %{LA-U:REMOTE_USER} (.+)
            RewriteRule . - [E=RU:%1]
            RequestHeader set X-Remote-User "%{RU}e" env=RU
        </Location>
</VirtualHost>
" > /tmp/reverse.conf
mv /tmp/reverse.conf /opt/app-root/reverse.conf

/usr/sbin/httpd $OPTIONS -DFOREGROUND
