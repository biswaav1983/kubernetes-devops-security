pipeline {
  agent any

environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "avisdocker/numeric-app:${GIT_COMMIT}"
    //applicationURL = "http://devsecops-demo.eastus.cloudapp.azure.com/"
    applicationURI = "/increment/99"
  }
	

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }

 stage("UnitTest-JUnit JaCoCo") {
      steps {
      sh "mvn test"
	}
  }

stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
   }


stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('SonarQube') {
        sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://10.0.3.26:9000 -Dsonar.login=1a6345e015c815082d08a9fcab5cfd1dbbfd88d7"
      }
       // timeout(time: 2, unit: 'MINUTES') 
	//{
       // script 
	//{
       //     waitForQualityGate abortPipeline: true
         //}

        //}
      }
    }


      steps {
        parallel(
          "Dependency Scan": {
            sh "mvn dependency-check:check"
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
          sh 'sudo docker build -t avisdocker/numeric-app:""$GIT_COMMIT"" .'
          sh 'docker push avisdocker/numeric-app:""$GIT_COMMIT""'
        }
      }
    }


  stage('Vulnerability Scan - Kubernetes') {
      steps {
        parallel(
          "OPA Scan": {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
          },
          "Kubesec Scan": {
            sh "bash kubesec-scan.sh"
          }
        )
      }
    }


stage('K8S Deployment - DEV') {
      steps {
        parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              sh "sed -i 's#replace#avisdocker/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
	      sh "kubectl apply -f k8s_deployment_service.yaml"
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

  }

}
}
