pipeline {
    agent { dockerfile {
        dir 'jenkins/stock-synthesis'
        args '-u 0:0'}
    }
    stages {
        stage('Git clone src for stock-synthesis') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'vlab/stock-synthesis']], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '1aa2d7c8-749f-4270-9de2-6ffcf0cd2beb', url: 'https://stock_synthesis.build@vlab.ncep.noaa.gov/git/stock-synthesis']]])
            }
        }
        stage('Build SS Exectutable') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'vlab/stock-synthesis']], submoduleCfg: [], userRemoteConfigs: [[credentialsId: '1aa2d7c8-749f-4270-9de2-6ffcf0cd2beb', url: 'https://stock_synthesis.build@vlab.ncep.noaa.gov/git/stock-synthesis']]])
                sh label: 'Check ADMB Version', script: 'admb'
                sh label: 'Double check source', script: 'admb'
            }
        }
    }
}