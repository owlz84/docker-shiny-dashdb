# docker-shiny-dashdb
## Host an R-Shiny application on Bluemix.
Congratulations, you are eight steps away from deploying your R Shiny application on Bluemix. This repository contains an example Docker recipe from which an image can be built and deployed into a Bluemix hosted container. It even works for applications that require a connection to a __dashDB__ database.  
Example currently running at http://169.44.2.30:3838/app.
### Requires:
- [Docker](https://www.docker.com/community-edition)
- [Bluemix CLI](https://clis.ng.bluemix.net/ui/home.html)
- [IBM containers plugin for Bluemix CLI](https://console.bluemix.net/docs/containers/container_cli_cfic_install.html#container_cli_cfic_install)
- A namespace configured in Bluemix container registry (see step 3 of the section: _Logging in to the IBM Bluemix Container Service CLI plug-in (bx ic)_ in the previous link)

### How to deploy:
0) Install the required software described above.
1) Clone this repository onto your local machine. You stand the best chance of successfully completing this step by using the [Github desktop client](https://desktop.github.com/) (Windows & Mac only).
2) Name your Shiny script _app.R_ and copy it into the _/app_ subfolder (overwriting the existing example _app.R_ file).
3) Copy any materials your app requires (images, stylesheets etc.) into _/app/www_.
4) In order to build the container, Docker looks at the instructions in the _Dockerfile_ text file. Dockerfiles describe the Docker 'Parent image' on which your image should be based and then list shell commands to be run (a) to get your container built and (b) to be executed when your container is run. More detail [here](https://docs.docker.com/engine/reference/builder/).  
You will need to amend this file to reflect the needs of your application in the following ways:
    - Add `install.packages()` statements for any additional __R__ libraries required by your app (copy from the examples already in there).
    - If you need to connect to a dashDB database, replace the placeholder hostname in the `RUN dsdriver/bin/db2cli writecfg add -database ...` commands on lines 48 and 49.
5) Using your shell / command prompt, log into Bluemix using the CLI and initialise the IBM-Containers plugin:  
`bx login --sso -a api.ng.bluemix.net`  
`bx ic init`
6) Build the image in the Bluemix containers registry:  
`bx ic build -t registry.ng.bluemix.net/your-namespace/docker-shiny-dashdb /local/path/to/docker-shiny-dashdb`.
    - Replace `your-namespace` and `/local/path/to` with the Bluemix repository service namespace you created at step 0 and the local path into which you cloned this repository respectively.
    - This will be relatively slow the first time, but Docker employs some clever caching as it goes. If you change nothing between builds then the next time you ask, the build will complete almost instantly. If you change something in line 1 of the Dockerfile then it will need to rebuild every step.
    - The logs are fairly helpful in diagnosing build errors. Often you'll find an __R__ package requires some additional library to be installed in Debian. If that's the case, add it to the list beginning `# Install dependencies...` in the Dockerfile (again, copy from the examples already there and don't forget the trailing `\`).
    - Note, the build will not necessarily fail if an __R__ package does not successfully install, so it's worth reviewing the logs even if the build appears to be a success.
7) Run the image as a new container in Bluemix:  
`bx ic run -p 3838:3838 --name your_app_name registry.ng.bluemix.net/your-namespace/docker-shiny-dashdb:latest`  
(again, substitute `your_app_name` for something appropriate to your app and `your-namespace` for your Bluemix container registry namespace)

You should now be able to log into the [Bluemix containers dashboard](https://console.bluemix.net/dashboard/containers) and e.g. assign your running container a public IP (which you will need to access it directly), reboot it etc.

Open an issue if there's something I need to look at.
