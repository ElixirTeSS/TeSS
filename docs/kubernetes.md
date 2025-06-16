# Kubernetes

TeSS can be run using Kubernetes for [production](#production). All Kubernetes manifests can be found under `k8s/` and they act as the main manifest reference.

[*HELM*] However, if you are looking for a more maintainable way for production (e.g., overcoming the multiple repetitions across the numerous k8s manifests), we recommend using the [TeSS Helm repo](https://github.com/ElixirTeSS/TeSS-Helm) especially made for this purpose. Both documentations were created during the same time (= you will find the same steps and informations + tailored to helm for the helm deployment) and should be updated accordingly.

Any modification of this `k8s/` directory must be updated in the [TeSS Helm repo](https://github.com/ElixirTeSS/TeSS-Helm) as well. Thank you 🙏

## Prerequisites

In order to run TeSS, you need to have the following prerequisites installed.

- Git
- Docker
- oc
- kubectl

These prerequisites are out of scope for this document but you can find more information about them at the following links:

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)
- [OpenShift CLI (oc)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/cli_tools/openshift-cli-oc#cli-getting-started)
- [kubectl](https://docs.redhat.com/en/documentation/openshift_container_platform/4.2/html/cli_tools/openshift-cli-oc#usage-oc-kubectl)

## Production

DISCLAIMER: for the database backup, `kartoza:pg-backup:14-3.1` was not used in Kubernetes because of file system permissions issues, instead we used `pg_dump` along with a k8 cronjob that performs a backup on Monday at 2:00AM (see `k8s/backup-cronjob.yaml`). To see how to access the backups see [backup section](#backup)

### TeSS configuration

#### `.env`

Create the `.env` file:

    cp env.sample .env

Make sure the various credentials are changed! You can set some random values for these fields like so:

    sed s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`/ -i .env
    sed s/DB_PASSWORD=.*/DB_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env
    sed s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env

Make sure to also set `ADMIN_EMAIL` and `ADMIN_USERNAME` for TeSS administration (please note `admin` is not available as a username).

Solr and Redis URL must be labelled with `-service` when deploying through Kubernetes:

    SOLR_URL=http://solr-service:8983/solr/tess
    REDIS_URL=redis://redis-service:6379/1
    REDIS_TEST_URL=redis://redis-service:6379/0

Replace `DB_HOST` and `DB_PORT` in .env with these values:

    DB_HOST=db-service
    DB_PORT=5432

#### `tess.yml` and `secrets.yml`

Setup the TeSS configuration files `tess.yml` and `secrets.yml`:

    cp config/tess.example.yml config/tess.yml
    cp config/secrets.example.yml config/secrets.yml

`tess.yml` is used to configure features and branding of your TeSS instance. `secrets.yml` is used to hold API keys etc.

Change `base_url` with your final URL in `tess.yml`. Make sure that it matches `host` in `k8s/app-route.yaml`.

### Build and push your TeSS image in a container registry

***Why***: We don't want to bake credentials in the image (i.e., leaving `.env`, `tess.yml` and `secrets.yml` in the image), instead we will setup Secrets with these three files. 

We will use `ghcr.io` (GitHub Container Registry, [see documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)). Your packages can be found in your GitHub Profile > `Packages` tab. You should have none or you may already have your own if you already used this service.

In GitHub, go to your `Settings` > `Developer settings` (bottom of the left menu) > `Personal access tokens` > `Tokens (classic)` > `Generate new token (classic)` (top right corner).

Name your token, tick `write:packages` + `delete:packages` and create your token. [GitHub documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic) recommends to save it as an environment variable, paste your token in the command below and execute it:

    export CR_PAT=YOUR_TOKEN

Sign in to the Container registry, modify the command below with your GitHub username:

    echo $CR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

Build the app and push the image to `ghcr.io`. Change the url with your own GitHub username, the name you want to give to your image and change the tag when you re/build it:

    docker build -f Dockerfile-k8 . -t ghcr.io/YOUR_GITHUB_USERNAME/YOUR_IMAGE_NAME:0.1.0 --platform linux/amd64,linux/arm64

To check that your image does not contain any credentials/sensitive information, you can locally run your image with the following command:

    docker run --rm -it ghcr.io/YOUR_GITHUB_USERNAME/YOUR_IMAGE_NAME:0.1.0 /bin/bash

Now that you are sure that neither `.env`, `tess.yml` nor `secrets.yml` are baked in your image you can push it on `ghcr.io`:

    docker push ghcr.io/YOUR_GITHUB_USERNAME/YOUR_IMAGE_NAME:0.1.0

Your TeSS image is now on GitHub, without credentials and private 🎉

### Allow Kubernetes to pull your private image

First, in the following files: `app-deployment.yaml`, `db-setup-job.yaml` and `sidekiq-deployment.yaml`, change `image` with the one you just built/pushed.

If your image/package is still Private, to be able to pull it, you must configure a Secret, change the username, password and email with your GitHub credentials:

    kubectl create secret docker-registry app-secrets-ghcr --docker-server=https://ghcr.io --docker-username=YOUR_GITHUB_USERNAME --docker-password=YOUR_GITHUB_TOKEN --docker-email=YOUR_EMAIL --dry-run=client -o yaml > k8s/app-secrets-ghcr.yaml

A small explanation here. This secret is now labelled as `app-secrets-ghcr` and when any Kubernetes manifest will try to pull your image as specified under `image` it will use the secret under `imagePullSecrets`.

### Set up `.env`, `tess.yml` and `secrets.yml` as secrets

Since none of these files are baked in your image, we will set them up as Secrets:

    kubectl create secret generic app-secrets-env --from-env-file=.env --dry-run=client -o yaml > k8s/app-secrets-env.yaml
    kubectl create secret generic app-secrets-config --from-file=config/secrets.yml --from-file=config/tess.yml --dry-run=client -o yaml > k8s/app-secrets-config.yaml
    
### Deploy

Connect to your cluster.

Build the app:

    oc apply -f k8s/

And you can now access your app at the designated URL!

## Backup

The current deployment allows a backup on `Monday at 2:00AM`, please make sure to have sufficient storage in `backup-pvc`, by default it has 10Gi. It might become quickly saturated so be aware of this while deploying!

In order to view the backups, you can create a debug pod:

    apiVersion: v1
    kind: Pod
    metadata:
    name: debug-pod
    spec:
    containers:
    - name: shell
        image: busybox
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - mountPath: /backups
        name: backup-storage
    volumes:
    - name: backup-storage
        persistentVolumeClaim:
        claimName: backup-pvc
    restartPolicy: Never

Then run these commands:

    kubectl apply -f debug-pod.yaml
    kubectl exec -it debug-pod -- ls -lh /backups
    
You should be able to see something like:

    -rw-r--r--    1 1001970000 1001970000  119.5K Jun  6 02:00 tess_20250606-020001.dump

Delete the debug-pod:

    kubectl delete pod debug-pod
