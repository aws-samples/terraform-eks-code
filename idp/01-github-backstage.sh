cd ~/environment/idp
export GITHUB_ORG_NAME=awsandyorg
npx '@backstage/cli' create-github-app ${GITHUB_ORG_NAME}
# If prompted, select all for permissions or select permissions listed in this page https://backstage.io/docs/integrations/github/github-apps#app-permissions
# In the browser window, allow access to all repositories then install the app.

# move it to a "private" location. 
mkdir -p private
GITHUB_APP_FILE=$(ls github-app-* | head -n1)
mv ${GITHUB_APP_FILE} private/github-integration.yaml
chmod 600 private/*
echo "Next get and store you github private access token into private/github-token"