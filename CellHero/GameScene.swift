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
    
    
    var bird = SKSpriteNode();
    var bird2 = SKSpriteNode();
    var sprite = SKSpriteNode();
    var ground = SKNode();
    var objTexture = SKTexture();
    var objTexture2 = SKTexture();

    var sheepTexture = SKTexture();
    
    
    var pipeMoveAndRemove = SKAction();
    var sheepMoveAndRemove = SKAction();
    var bgMoveAndRemove = SKAction();
    let pipeGap = 150.0;
    var skyColor = SKColor();
    
    var scoreLabelNode = SKLabelNode();
    var score = NSInteger();
    var reset = Bool();
    var pipes:SKNode!;
    var moving:SKNode!;
    var pipes2:SKNode!;
    var moving2:SKNode!;
    
    
    var clouds = SKNode();
    var hasClouds = false;
    
    let birdCategory:UInt32 = 1<<0
    let worldCategory:UInt32 = 1<<1
    let pipeCategory:UInt32 = 1<<2
    
    let birdCategory2:UInt32 = 1<<3
    let worldCategory2:UInt32 = 1<<4
    let pipeCategory2:UInt32 = 1<<5
    
    let scoreCategory:UInt32 = 1<<6
    
    var debug = true;
    let motionManager = CMMotionManager();
    
    var screenWidth:CGFloat = 0;
    var screenHeight:CGFloat = 0;
    
    
    var currentMaxAccelX:Double = 0;
    var currentMaxAccelY:Double = 0;
    
    var rightScreen = SKShapeNode()
    var background2 = SKShapeNode();
    var halfFrame:Float = 2;
    
    var birdZ:CGFloat = 0.0;
    var birdX:CGFloat = 0.0;
    
    override func didMoveToView(view: SKView) {
        
        screenWidth = view.frame.width;
        screenHeight = view.frame.height;
        
        let distanceToMove = CGFloat(self.frame.size.height);
        let movePipes = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.01*distanceToMove));
        let moveSheeps = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.007*distanceToMove));
        let moveBg = SKAction.moveByX(0, y: -distanceToMove, duration: NSTimeInterval(0.01*distanceToMove));
        let resetBg = SKAction.moveBy(CGVectorMake(0, +distanceToMove), duration: NSTimeInterval(0));
        
        let removePipes = SKAction.removeFromParent();
        
        pipeMoveAndRemove = SKAction.sequence([movePipes,removePipes]);
        sheepMoveAndRemove = SKAction.sequence([moveSheeps,removePipes]);
        bgMoveAndRemove = SKAction.repeatActionForever(SKAction.sequence([moveBg,resetBg]));

        
        //gyro
        motionManager.accelerometerUpdateInterval = 0.2
        halfFrame = Float(self.frame.width)/2;
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {(accelerometerData: CMAccelerometerData!, error:NSError!)in
            self.outputAccelerationData(accelerometerData.acceleration)
            if (error != nil)
            {
                println("\(error)")
            }
        })
        
        reset = false;
        
        self.physicsWorld.contactDelegate = self;
        
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0);
        self.backgroundColor = skyColor;
    
        var background2 = SKNode();
        background2.zPosition = 5;
        background2.position = CGPointMake(self.frame.width/2, self.frame.height/2);
        
        var bgTexture = SKTexture(imageNamed: "grass");
        bgTexture.filteringMode = SKTextureFilteringMode.Nearest;
        
        for index in -30...30 {
            let bg = SKSpriteNode(texture: bgTexture);
            bg.zPosition = -100;
            //bg.anchorPoint = CGPointZero;
            bg.position = CGPoint(x: 0, y: bg.size.height * CGFloat(index))
            bg.name = "background";

            var b2 = bg.copy() as SKSpriteNode;
            b2.position = CGPoint(x: self.frame.size.width/2, y: bg.size.height * CGFloat(index))
            b2.zPosition = 7;
                
            self.addChild(bg);
            self.addChild(b2);
            bg.runAction(bgMoveAndRemove);
            b2.runAction(bgMoveAndRemove);
        }
        
        moving = SKNode();
        self.addChild(moving);
        
        
        var birdTexture = SKTexture(imageNamed: "bird-01");
        birdTexture.filteringMode = SKTextureFilteringMode.Nearest;

        var birdTexture2 = SKTexture(imageNamed: "bird-02");
        birdTexture2.filteringMode = SKTextureFilteringMode.Nearest;

        
        objTexture = SKTexture(imageNamed: "object_l");
        objTexture.filteringMode = SKTextureFilteringMode.Nearest;

        objTexture2 = SKTexture(imageNamed: "object_r");
        objTexture2.filteringMode = SKTextureFilteringMode.Nearest;

        
        sheepTexture = SKTexture(imageNamed: "sheep");
        sheepTexture.filteringMode = SKTextureFilteringMode.Nearest;
        
        bird = SKSpriteNode(texture: birdTexture);
        bird.setScale(0.4);
        bird.position = CGPoint(x: self.frame.size.width / 4, y: self.frame.size.height*0.6);
        
        bird.zPosition = 10;
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/4);
        bird.physicsBody?.dynamic = false;
        bird.physicsBody?.allowsRotation = false;
        
        bird.physicsBody?.categoryBitMask = birdCategory;
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory;
        
        
        //spawnpipes
        
        let spawn = SKAction.runBlock({() in self.spawnPipes()});
        let delay = SKAction.waitForDuration(NSTimeInterval(0.5));
        let spawnThenDelay = SKAction.sequence([spawn,delay]);
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay);
        
        self.runAction(spawnThenDelayForever);
        
        let box = CGRectMake(self.frame.width/2, 0, self.frame.width/2, self.frame.height/2);
        var bgcrop = SKCropNode();
        var mask = SKSpriteNode(color:SKColor.blackColor(), size: CGSizeMake(self.frame.width, self.frame.height))
        mask.anchorPoint = CGPointZero;
        
        bgcrop.maskNode = mask;
        bgcrop.addChild(background2);
        rightScreen.addChild(bgcrop);
        
        bird2 = bird.copy() as SKSpriteNode;
        bird2.texture = birdTexture2;
        bird.physicsBody?.dynamic = true;
        bird2.position = CGPoint(x: self.frame.size.width * 3 / 4, y: self.frame.size.height*0.6);
        bird2.zPosition = 11;
        
        moving2 = SKNode();
        rightScreen.addChild(moving2);
        rightScreen.addChild(bird2);
        
        self.addChild(rightScreen);
        
        
        //skor
        score = 0;
        scoreLabelNode = SKLabelNode(fontNamed: "Calibri");
        scoreLabelNode.position = CGPointMake(self.frame.size.width - 30, 3*self.frame.size.height/4 + 100);
        scoreLabelNode.zPosition = 50;
        scoreLabelNode.text = String(score);
        self.addChild(scoreLabelNode);
        
        
        if(!debug) {
            return;
        }
        
        self.addChild(clouds);
        self.addChild(bird);
    }
    
    func spawnPipes() {
        
        if (arc4random_uniform(10) < 2) {
            
            let z:CGFloat = 20;
            let x:CGFloat = CGFloat(arc4random_uniform(1000))/2000 * self.frame.size.width;
            
            println(x - z * 0.8);
            
            let sheep = SKSpriteNode(texture: sheepTexture);
            sheep.position = CGPointMake(x - z * 0.8, self.frame.size.height * 2);
            sheep.zPosition = 20;
            sheep.setScale(0.3);
            sheep.physicsBody = SKPhysicsBody(rectangleOfSize: sheep.size);
            sheep.physicsBody?.dynamic = false;
            sheep.physicsBody?.categoryBitMask = scoreCategory;
            sheep.physicsBody?.contactTestBitMask = birdCategory;
            sheep.runAction(pipeMoveAndRemove);
            moving.addChild(sheep);
            
            println(self.frame.width/2 * 1.2 + 50 + x + z);
            let sheep2 = sheep.copy() as SKSpriteNode;
            sheep2.position = CGPointMake(self.frame.width/2 * 1.2 + 50 + x + z, self.frame.size.height * 2);
            sheep2.zPosition = 10;
            sheep2.runAction(pipeMoveAndRemove);
            moving2.addChild(sheep2);
        }
        
        let z:CGFloat = 20;
        let x:CGFloat = CGFloat(arc4random_uniform(1000))/2000 * self.frame.size.width;
        let object = SKSpriteNode(texture: objTexture);
        object.position = CGPointMake(x - z * 0.8, self.frame.size.height * 2);
        object.zPosition = 6;
        object.setScale(0.9);
        object.physicsBody = SKPhysicsBody(rectangleOfSize: object.size);
        object.physicsBody?.dynamic = false;
        object.physicsBody?.categoryBitMask = pipeCategory;
        object.physicsBody?.contactTestBitMask = birdCategory;
        
        let object2 = object.copy() as SKSpriteNode;
        object2.texture = objTexture2;
        // 50 is a eye buffer
        object2.position = CGPointMake(self.frame.width/2 * 1.2 + 50 + x + z, self.frame.size.height * 2);
        object2.zPosition = 10;
        
        object.runAction(pipeMoveAndRemove);
        object2.runAction(pipeMoveAndRemove);

        moving.addChild(object);
        moving2.addChild(object2);
    }
    
    func gameReset()-> Void {
        bird.position = CGPoint(x: self.frame.size.width * 1 / 4 * 1.2, y: self.frame.size.height*0.6);
        bird.physicsBody?.velocity = CGVectorMake(0, 0);
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.speed = 1;
        bird.zRotation = 0;
        
        bird2.position = CGPoint(x: self.frame.size.width * 3 / 4 * 1.2, y: self.frame.size.height*0.6);
        bird2.physicsBody?.velocity = CGVectorMake(0, 0);
        bird2.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird2.speed = 1;
        bird2.zRotation = 0;
        
        
        score = 0;
        reset = false;
        moving.removeAllChildren();
        moving2.removeAllChildren();
        scoreLabelNode.text = String(score);
        moving.speed = 1; // ground hareket animasyonu tekrar başlatır
        moving2.speed = 1; // ground hareket animasyonu tekrar başlatır
    }
    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if reset {
            self.gameReset();
        }
    }
    func didBeginContact(contact: SKPhysicsContact) {
        if(moving.speed > 0 && birdZ < -0.9){
            
            if(( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
                
                
                contact.bodyA.node?.removeFromParent();
                score++;
                scoreLabelNode.text = String(score);
                
                scoreLabelNode.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: NSTimeInterval(0.1)),SKAction.scaleTo(1, duration: NSTimeInterval(0.3))]));
                //self.runAction(SKAction.playSoundFileNamed("sheep.wav", waitForCompletion: false));
            }
            else {
                
                moving.speed = 0;
                moving2.speed = 0;
                bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
                bird2.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
                bird.speed = 0;
                bird2.speed = 0;
                self.removeActionForKey("bitir")
                self.runAction(SKAction.sequence([SKAction.repeatAction(SKAction.sequence([SKAction.waitForDuration(NSTimeInterval(0.05)), SKAction.runBlock({
                    self.backgroundColor = self.skyColor;
                    self.background2.fillColor = self.skyColor;
                }), SKAction.waitForDuration(NSTimeInterval(0.05))]), count:4), SKAction.runBlock({
                    self.reset = true
                })]), withKey: "bitir")
                
                self.runAction(SKAction.sequence([SKAction.waitForDuration(3), SKAction.runBlock({
                    self.gameReset();
                })]));
            }
        }
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        
    
        if moving.speed == 0 {
            return;
        }
        
        self.enumerateChildNodesWithName("background", usingBlock: { (node:SKNode!, stop:UnsafeMutablePointer <ObjCBool>) -> Void in
            let bg = node as SKSpriteNode;
            bg.position = CGPointMake(bg.position.x, bg.position.y - 5);
            
            if bg.position.x <= -bg.size.width {
                bg.position = CGPointMake(bg.position.x + bg.size.width * 2, bg.position.y);
            }
        });
        
        if (!hasClouds) {
            if birdZ > -0.9 {
                hasClouds = true;
                var path = NSBundle.mainBundle().pathForResource("Clouds", ofType: "sks")
                for index in 1...5 {
                    var cloud:SKEmitterNode = NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as SKEmitterNode;
                    let x:CGFloat = CGFloat(arc4random_uniform(1000))/2000 * self.frame.size.width;
                    let y:CGFloat = CGFloat(arc4random_uniform(1000))/1000 * self.frame.size.height;
                    cloud.position = CGPointMake(x, y);
                    cloud.zPosition = 10;
                    
                    
                    let cloud2 = cloud.copy() as SKEmitterNode;
                    cloud2.position = CGPointMake(self.frame.width/2 + x, y);
                    cloud.zPosition = 10;
                    
                    clouds.addChild(cloud);
                    clouds.addChild(cloud2);
                }

            }
        } else {
            if birdZ < -0.9 {
                hasClouds = false;
                
                for cloud in clouds.children {
                    cloud.runAction(SKAction.sequence([  SKAction.fadeAlphaTo(0, duration: 0.8), SKAction.runBlock({
                        cloud.removeFromParent();
                    }) ]));
                }
            }
        }
        
        var maxX:CGFloat = self.frame.width/2;
        var minX:CGFloat = 0;
        
        var zoomFactor:CGFloat = 30.0;
        
        var newX = (-birdX + 0.5) * (maxX - minX);
        var newY:CGFloat = 300 + zoomFactor * (birdZ + 1);
        var newZ:CGFloat = zoomFactor * (birdZ + 1);
        
        if newY > 400 {
            newY = 400;
        }
        
        if newZ > 100 {
            newZ = 50;
        }
        
        if newZ < 0 {
            newZ = 0;
        }
        

        if  (!self.reset) {
            bird.position = CGPointMake((newX+newZ) * 0.8, newY);
            bird2.position = CGPointMake((self.frame.width/2+newX-newZ) * 1.2, newY);
        }
    }
    
    func outputAccelerationData(acceleration:CMAcceleration)
    {
        birdZ = CGFloat(acceleration.z);
        birdX = CGFloat(acceleration.y);
    }

}