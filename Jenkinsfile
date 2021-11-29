phttp://192.168.56.106:8080/github-webhook/ipeline {
  agent any

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true" 
        archive 'target/*.jar'
      }
    }



  }

}
