pipeline {
  agent any
  stages {
	    stage('intialize') {
		    steps {
		        	echo 'hello'
	      		}
	    }
    
	    stage('Run Robot Tests') {
	      steps {
		        	robot demmm.robot
	      		}
	      post {
        	always {
		        script {
		          step(
				[
							$class : 'RobotPublisher',
							outputPath : outputDirectory,
							outputFileName : "*.xml",
							disableArchiveOutput : false,
							passThreshold : 100,
							unstableThreshold: 95.0,
							onlyCritical : true,
							otherFiles : "*.png",
					]
				)
		        }
	  		}		
	    }
	}    
  }
  
}
