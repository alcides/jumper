//
//  GameScene.swift
//  flappyBirdSwift
//
//  Created by Anıl Gülgör on 24.10.2014.
//  Copyright (c) 2014 SnowGames. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var columns: [CGFloat] = []

    var birdLeft  = SKSpriteNode();
    var birdRight = SKSpriteNode();
    
    var sprite = SKSpriteNode();
    var pipeUpTexture = SKTexture();
    var pipeDownTexture = SKTexture();
    var pipeMoveAndRemove = SKAction();
    var groundTexture = SKTexture();
    let pipeGap = 150.0;
    var moveGroundSpritesForever = SKAction();
    var skyColor = SKColor();
    
    var scoreLabelNode = SKLabelNode();
    var score = NSInteger();
    var reset = Bool();
    var pipes:SKNode!;
    var moving:SKNode!;
    
    var goUp:Double = 0;
    
    let birdCategory:UInt32 = 1<<0
    let worldCategory:UInt32 = 1<<1
    let pipeCategory:UInt32 = 1<<2
    
    let birdCategory2:UInt32 = 1<<3
    let worldCategory2:UInt32 = 1<<4
    let pipeCategory2:UInt32 = 1<<5
    
    let scoreCategory:UInt32 = 1<<6

    var debug = true;
    var gyroYValue = NSInteger();
    var gyroYValueLabelNode = SKLabelNode();
    var acclYValue = NSInteger();
    var acclYValueLabelNode = SKLabelNode();
    let motionManager = CMMotionManager();
    

    
    var rightScreen = SKSpriteNode()
    
    override func didMoveToView(view: SKView) {
        
        //core motion
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.gyroUpdateInterval = 0.2
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {(accelerometerData: CMAccelerometerData!, error:NSError!)in
            self.outputAccelerationData(accelerometerData.acceleration)
            if (error != nil)
            {
                println("\(error)")
            }
        })
        motionManager.startGyroUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {(gyroData: CMGyroData!, error: NSError!)in
            self.outputRotationData(gyroData.rotationRate)
            if (error != nil)
            {
                println("\(error)")
            }
        })
 
        reset = false;

        //self.physicsWorld.gravity = CGVectorMake(0.0, -5.0);
        self.physicsWorld.contactDelegate = self;
        
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0);
        self.backgroundColor = skyColor;
        
        moving = SKNode();
        self.addChild(moving);
        pipes = SKNode();
        moving.addChild(pipes);
        
        groundTexture = SKTexture(imageNamed: "ground");
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest;
        
        moveGround();
        
        for var i:CGFloat = 0; i<2.0 + self.frame.size.width; i++ {
            sprite = SKSpriteNode(texture: groundTexture);
            sprite.setScale(2.0);
            sprite.position = CGPointMake(i*sprite.size.width, sprite.size.height/2);
            sprite.runAction(moveGroundSpritesForever);
            moving.addChild(sprite);
        }
        
        var ground = SKNode();
        ground.position = CGPointMake(groundTexture.size().width, groundTexture.size().height);
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height));
        ground.physicsBody?.dynamic = false;
        ground.physicsBody?.categoryBitMask = worldCategory;
        self.addChild(ground);
        
        pipeUpTexture = SKTexture(imageNamed: "pipeup");
        pipeDownTexture = SKTexture(imageNamed: "pipedown");
        pipeUpTexture.filteringMode = .Nearest;
        pipeDownTexture.filteringMode = .Nearest;
        
        let distanceToMove = CGFloat(self.frame.size.width * 2 * pipeUpTexture.size().width);
        let movePipes = SKAction.moveByX(-distanceToMove, y: 0, duration: NSTimeInterval(0.01*distanceToMove));
        let removePipes = SKAction.removeFromParent();
        
        pipeMoveAndRemove = SKAction.sequence([movePipes,removePipes]);

        
        birdLeft  = createWorld(0);
        birdRight = createWorld(self.frame.size.width/2);
        
        self.addChild(birdLeft);
        self.addChild(birdRight);
    }
    
    func createWorld(offset: CGFloat) -> SKSpriteNode {
        
        var birdTexture = SKTexture(imageNamed: "bird-01");
        birdTexture.filteringMode = SKTextureFilteringMode.Nearest;
        
        var bird = SKSpriteNode();
        bird = SKSpriteNode(texture: birdTexture);
        bird.setScale(2);
        bird.position = CGPoint(x: (self.frame.size.width/2)*0.35+offset, y: self.frame.size.height*0.6);
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2);
        bird.physicsBody?.dynamic = true;
        bird.physicsBody?.allowsRotation = false;
        
        bird.physicsBody?.categoryBitMask = birdCategory;
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory;
        
        /* add separator line */
        var line = SKShapeNode();
        let box = CGRectMake(self.frame.width/2, 0, self.frame.width/2, self.frame.height);
        line.path = UIBezierPath(rect: box).CGPath;
        self.addChild(line);
        
        //spawnpipes
        let spawn = SKAction.runBlock({() in self.spawnPipes()});
        let delay = SKAction.waitForDuration(NSTimeInterval(2.0));
        let spawnThenDelay = SKAction.sequence([spawn,delay]);
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay);
        
        self.runAction(spawnThenDelayForever);
        
        //core
        score = 0;
        scoreLabelNode = SKLabelNode(fontNamed: "Calibri");
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), 3*self.frame.size.height/4 + 100);
        scoreLabelNode.zPosition = 50;
        scoreLabelNode.text = String(score);
        self.addChild(scoreLabelNode);
        
        
        if(!debug) {
            return bird;
        }
        
        //gyro
        gyroYValue = 0;
        gyroYValueLabelNode = SKLabelNode(fontNamed: "Calibri");
        gyroYValueLabelNode.text = NSString(format:"%.4f", "0")
        gyroYValueLabelNode.position = CGPointMake(CGRectGetMaxX(self.frame) - gyroYValueLabelNode.frame.width, CGRectGetMaxY(self.frame)-150);
        gyroYValueLabelNode.zPosition = 50;
        self.addChild(gyroYValueLabelNode);
        
        //accl
        acclYValue = 0;
        acclYValueLabelNode = SKLabelNode(fontNamed: "Calibri");
        acclYValueLabelNode.text = NSString(format:"%.4f", "0")
        acclYValueLabelNode.position = CGPointMake(CGRectGetMaxX(self.frame) - acclYValueLabelNode.frame.width, CGRectGetMaxY(self.frame)-200);
        acclYValueLabelNode.zPosition = 50;
        self.addChild(acclYValueLabelNode);
        
        return bird;
    }
    
    func moveGround() {
        let moveGroundSprite = SKAction.moveByX(-groundTexture.size().width*2 , y: 0, duration: NSTimeInterval(0.007*groundTexture.size().width*2));
        let resetGroundSprite = SKAction.moveByX(groundTexture.size().width*2, y: 0, duration: 0);
        moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]));
    }
    
    func spawnPipes(offset: CGFloat) {
        let pipePair = SKNode();
        pipePair.position = CGPointMake(offset + pipeUpTexture.size().width * 2 , 0);
        pipePair.zPosition = -10;
        
        let height = UInt32(self.frame.size.height/4);
        let y = arc4random() % height + height;
        
        let pipeDown = SKSpriteNode(texture: pipeDownTexture);
        pipeDown.setScale(0.5);
        pipeDown.position = CGPointMake(0, CGFloat(y) + pipeDown.size.height + CGFloat(pipeGap));
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size);
        pipeDown.physicsBody?.dynamic = false;
        pipeDown.physicsBody?.categoryBitMask = pipeCategory;
        pipeDown.physicsBody?.contactTestBitMask = birdCategory;

        pipePair.addChild(pipeDown);
        pipePair.runAction(pipeMoveAndRemove);
        pipes.addChild(pipePair);
    }
    
    func spawnPipes() {
        //spawnPipes(0);
        spawnPipes(self.frame.size.width);
        
        
        /*let pipeUp = SKSpriteNode(texture: pipeUpTexture);
        pipeUp.setScale(0.5);
        pipeUp.position = CGPointMake(0, CGFloat(y));
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size);
        pipeUp.physicsBody?.dynamic = false;
        pipeUp.physicsBody?.categoryBitMask = pipeCategory;
        pipeUp.physicsBody?.contactTestBitMask = birdCategory;
        pipePair.addChild(pipeUp);
        
        var contactNode = SKNode();
        contactNode.position = CGPointMake(pipeDown.size.width+bird.size.width/2, CGRectGetMidY(self.frame));
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipeUp.size.width, self.frame.size.height));
        contactNode.physicsBody?.dynamic = false;
        contactNode.physicsBody?.categoryBitMask = scoreCategory;
        contactNode.physicsBody?.contactTestBitMask = birdCategory;
        pipePair.addChild(contactNode);*/
        
    }
    
    func gameReset()-> Void {
        resetBird(birdLeft, withOffset: 0);
        resetBird(birdRight, withOffset: self.frame.size.width/2);
        
        score = 0;
        reset = false;
        pipes.removeAllChildren();
        scoreLabelNode.text = String(score);
        moving.speed = 1; // ground hareket animasyonu tekrar başlatır
    }
    
    func resetBird(bird: SKSpriteNode, withOffset offset: CGFloat) {
        bird.position = CGPoint(x: (self.frame.size.width/2)*0.35+offset, y: self.frame.size.height*0.6);
        bird.physicsBody?.velocity = CGVectorMake(0, 0);
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.speed = 1;
        bird.zRotation = 0;
    }
    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if reset{
            self.gameReset();
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if(moving.speed > 0){
            
            if(( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
                
                //skoru arttırır ve label a yazar
                score++;
                print("anıl \(score)");
                scoreLabelNode.text = String(score);
                
                //skor artınca label büyüt ve küçült animasyonu
                scoreLabelNode.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: NSTimeInterval(0.1)),SKAction.scaleTo(1, duration: NSTimeInterval(0.1))]));
            }
            else {
                moving.speed = 0;
                birdCollision(birdLeft);
                birdCollision(birdRight);
                
                self.runAction(SKAction.sequence([SKAction.repeatAction(SKAction.sequence([SKAction.runBlock({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0);
                }),SKAction.waitForDuration(NSTimeInterval(0.05)), SKAction.runBlock({
                    self.backgroundColor = self.skyColor;
                }), SKAction.waitForDuration(NSTimeInterval(0.05))]), count:4), SKAction.runBlock({
                    self.reset = true
                })]), withKey: "bitir")
            }
        }
    }
    
    func birdCollision(bird: SKSpriteNode) {
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.runAction(SKAction.rotateByAngle(CGFloat(M_PI)*CGFloat(bird.position.y)*0.01, duration:1), completion:{bird.speed = 0});
    }
    
    func clamp(min:CGFloat,max:CGFloat,value:CGFloat)->CGFloat {
        if(value>max){
            return max;
        }
        else if(value<min){
            return min;
        }
        else {
            return value;
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        birdLeft.position.y.advancedBy(CGFloat(goUp));
        birdRight.position.y.advancedBy(CGFloat(goUp));
        goUp = 0;
    }
    
    func outputAccelerationData(acceleration:CMAcceleration) {
        gyroYValueLabelNode.text = NSString(format:"%.4f", acceleration.z);
        goUp = acceleration.z * 2;
    }
    
    func outputRotationData(rotation:CMRotationRate) {
        acclYValueLabelNode.text = NSString(format: "%.4f", rotation.z);
    }
}