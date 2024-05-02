#!/usr/bin/env groovy
@Library('shared-jenkins-library@main')
import com.dxc.sics.Artifactory

def splitModules(String moduleName) {
  String value = ''
  Map submodules = readYaml file: '../../../modules.yml'
  submodules.parcels."${moduleName}".each { module ->
        value = value + module + ','
  }
  return value.replaceAll(''',$''', '''''')
}

pipeline {
  agent {
    dockerfile {
      filename 'Dockerfile'
      registryUrl 'https://index.docker.io/v1/'
      registryCredentialsId 'sics-docker-hub'
      args '-u root:root -v "/var/run/docker.sock:/var/run/docker.sock:rw"'
    }
  }

  environment {
        MAVEN_OPTS = '-Xss2000k -Xms256m -Xmx8g'
  }

  options {
    timeout(time: 12, unit: 'HOURS')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '100', artifactNumToKeepStr: '100'))
  }

  stages {
    stage('Init') {
      steps {
        checkout scm
        script {
          Artifactory.initMavenSettings(this)
        }
      }
    }
    stage('Clone') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'githubapp-sics', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASSWORD')]) {
            sh '''
              set +x
              git config --global user.email "pdxc-jenkins@dxc.com"
              git config --global user.name "pdxc-jenkins"
              git clone https://${GIT_USER}:${GIT_PASSWORD}@github.dxc.com/sics/sics5.git
            '''
          }
        }
      }
    }
    stage('Install') {
      steps {
        dir('sics5/source') {
          sh 'mvn -B clean install'
        }
      }
    }
    stage('Scan') {
      steps {
        script {
          withCredentials([string(credentialsId:'ASSURE-SONAR-HOST', variable:'SONARHOST')]) {
            withCredentials([string(credentialsId:'ASSURE-SONAR-TOKEN', variable:'SONARTOKEN')]) {
              dir('sics5/source/parcels') {
                Map submodules = readYaml file: '../../../modules.yml'
                submodules.parcels.each { submodule ->
                  def moduleNames = splitModules(submodule.key)
                  stage("Scan " + submodule.key) {
                    sh "mvn -B -pl .,${moduleNames} sonar:sonar -Dsonar.sourceEncoding=ISO-8859-1 -Dsonar.login=${SONARTOKEN} -Dsonar.host.url=${SONARHOST} -Dsonar.projectKey=ASR-assure-reinsurance-${submodule.key} -Dsonar.projectName=assure-reinsurance-${submodule.key}"
                  }
                }
              }
              dir('sics5/source/server') {
                sh 'mvn -B sonar:sonar -Dsonar.sourceEncoding=ISO-8859-1 -Dsonar.login=${SONARTOKEN} -Dsonar.host.url=${SONARHOST} -Dsonar.projectKey=ASR-assure-reinsurance-server -Dsonar.projectName=assure-reinsurance-server'
              }
            }
          }
        }
      }
    }
  }
}
