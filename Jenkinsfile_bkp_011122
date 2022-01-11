pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "avisdocker/numeric-appv1:${GIT_COMMIT}"
    applicationURL = "http://localhost/"
    applicationURI = "/increment/99"
  }

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "/opt/maven/bin/mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }

    stage('Unit Tests - JUnit and JaCoCo') {
      steps {
        sh "/opt/maven/bin/mvn test"
      }
    }
    
   stage('Mutation Tests - PIT') {
      steps {
        sh "/opt/maven/bin/mvn org.pitest:pitest-maven:mutationCoverage"
      }
    }


   stage('SonarQube - SAST') { 

      steps { 

        sh "/opt/maven/bin/mvn sonar:sonar -Dsonar.projectKey=jenkins-numeric -Dsonar.host.url=http://10.201.40.33:9000 -Dsonar.login=2079426835b697d11581edadba9ff7cc6a9593ec" 

      } 

    } 

   stage('Vulnerability Scan - Docker ') {
      steps {
        parallel(
          "Dependency Scan": {
            sh "/opt/maven/bin/mvn dependency-check:check"
          },
          "Trivy Scan": {
            sh "bash trivy-docker-image-scan.sh"
          },

	"OPA Conftest": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
          }
        )
      }
    }

    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'docker build -t avisdocker/numeric-appv1:""$GIT_COMMIT"" .'
          sh 'docker push avisdocker/numeric-appv1:""$GIT_COMMIT""'
        }
      }
    }

   stage('Vulnerability Scan - Kubernetes') {
      steps {
        sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
      }
    }

//    stage('K8S Deployment - DEV') {
    
//	steps {
//        withKubeConfig([credentialsId: 'kubeconfig']) {
//          sh "sed -i 's#replace#avisdocker/numeric-appv1:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
//          sh "kubectl apply -f k8s_deployment_service.yaml"
//        }
//      }
//    }


	stage('K8S Deployment - DEV') {
     	 steps {
         parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment.sh"
            }
          },
          "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "bash k8s-deployment-rollout-status.sh"
            }
          }
        )
      }
    }


  }

    post {
     always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }

    // success {

    // }

    // failure {

    // }
  }

}

