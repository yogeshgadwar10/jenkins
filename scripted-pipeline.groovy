node {
    stage('pull'){
        echo 'PULL SUCCESS'
    }
    stage('build')
    {
        echo 'Application build'
    } 
    stage('Deploy'){
        echo 'Application Deploy'
    }

}