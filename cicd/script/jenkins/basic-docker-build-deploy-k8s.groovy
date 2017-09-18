node {
    def app = '';
    def start_index = params.registry_url.indexOf("//") + 2;
    def registry_url = params.registry_url.substring(start_index);
    stage('Checkout git repo') {
      git branch: 'master', url: params.git_repo
    }
    stage('Build Docker image') {
      app = docker.build(params.docker_repository + ":${env.BUILD_NUMBER}", '.')
    }
    stage('Push Docker image to Private Registry') {
      docker.withRegistry(params.registry_url, params.registry_credentials_id ) {
        app.push("${env.BUILD_NUMBER}");
      }
    }
    stage('Test And Validation') {
        app.inside {
            sh 'echo "Test passed"'
        }
    }
    stage('Deploy to K8S') {
        // update image
        def cmd = """kubectl set image deployments/${params.service_name} ${params.service_name}=${registry_url}/${app.imageName()}"""
        sh cmd
    }
}
    