# Rogue Purple Air Sensor Detector Using GitHub Actions

## How it works?  

### What is `GitHub Actions`?  

GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that allows you to automate your build, test, and deployment pipeline. You can create workflows that build and test every pull request to your repository, or deploy merged pull requests to production.  

GitHub Actions makes it easy to automate all your software workflows. Build, test, and deploy your code right from GitHub. Make code reviews, branch management, and issue triaging work the way you want.

I came up with the idea that the GitHub Actions will work if we use workflow automation including issue triaging. Also, it is completely free if we push it into the public repository!

### Programming `GitHub Actions`

We can program it to meet our needs by making a YAML file.

See [GitHub Actions config yaml](https://github.com/YONGHUNI/rougue_PA_detector/blob/main/.github/workflows/check.yml) for a better understanding.

**1. Cron Job, *i.e.*, Shceduled job** # every 30 minutes
> on:  
> &nbsp; schedule:  
> &nbsp; &nbsp;  \- cron: '*/30 * * * *' 

**2. Step 1: Check out the repository**
> This action checks out your repository under $GITHUB_WORKSPACE, so your workflow can access it.


**3. Step 2: Install OS(Ubuntu) dependencies**(programs for R packages)  
Using the premade action(awalsh128/cache-apt-pkgs-action@latest) that caches installed packages from the last run, we can save a lot of time  
> \- name: Install Ubuntu dependencies  
  &nbsp;uses: awalsh128/cache-apt-pkgs-action@latest  
  &nbsp; &nbsp;with:   
  &nbsp;  &nbsp;&nbsp;packages: >-  
  &nbsp;     &nbsp; &nbsp;&nbsp;libcurl4-openssl-dev  
  &nbsp;  &nbsp;&nbsp;version: 1  


**4. Step 3: Install R**  
> \- name: Install R  
  &nbsp;&nbsp;uses: r-lib/actions/setup-r@v2  

**5. Step 4: Install R dependencies**(R packages)  
Using the premade action(r-lib/actions/setup-renv@v2) that caches installed packages from the last run, we can save a lot of time  
I used the `renv` package to manifest and clone the environment  

> \- name: Install R dependency  
  &nbsp;&nbsp;uses: r-lib/actions/setup-renv@v2  
  &nbsp;&nbsp;with:  
  &nbsp;&nbsp;&nbsp;profile: '"packages"'  
  &nbsp;&nbsp;&nbsp;cache-version: 2  



**6. Step 5: run the main program**  
>name: run main.R  
> $$\vdots$$  
>run: Rscript --verbose main.R #run main  

**7. Step 6~7: steps for sending discord messages**  

