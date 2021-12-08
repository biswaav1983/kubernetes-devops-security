pipeline {
  agent any

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }

    stage('Unit Tests - JUnit and JaCoCo') {
      steps {
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }
    
   stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
      }
    }


   stage('SonarQube - SAST') { 

      steps { 

        sh "mvn sonar:sonar -Dsonar.projectKey=jenkins-numeric -Dsonar.host.url=http://10.201.40.33:9000 -Dsonar.login=2079426835b697d11581edadba9ff7cc6a9593ec" 

      } 

    } 

   stage('Vulnerability Scan - Docker ') {
      steps {
        sh "mvn dependency-check:check"
      }
      post {
        always {
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }
      }
    }

    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'docker build -t avisdocker/numeric-app-v1:""$GIT_COMMIT"" .'
          sh 'docker push avisdocker/numeric-app-v1:""$GIT_COMMIT""'
        }
      }
    }


     stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh "sed -i 's#replace#avisdocker/numeric-app-v1:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
          sh "kubectl apply -f k8s_deployment_service.yaml"
        }
      }
    }

  }

}

