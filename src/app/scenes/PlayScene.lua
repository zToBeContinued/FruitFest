local FruitItem = import("app.scenes.FruitItem")
local PlayScene = class("PlayScene", function()
    return display.newScene("PlayScene")
end)

function PlayScene:ctor()
    math.newrandomseed()
    --init value
    self.highScore = cc.UserDefault:getInstance():getIntegerForKey("HighScore")
    --当前关卡
    self.stage = cc.UserDefault:getInstance():getIntegerForKey("Stage")
    if self.stage == 0 then
        self.stage = 1
    end
    --通关分数
    self.target = self.stage * 200
    self.curScore = 0

    self.xCount = 8    --水平方向水果数
    self.yCount = 8    --垂直方向水果数
    self.fruitGap = 0  --水果间距

    self.scoreStart = 5   --水果基分
    self.scoreStep = 10   --加成分数
    self.activeScore = 0  --当前高亮的水果得分

    -- 初始化随机数
    math.newrandomseed()
    self.matrixLBX = (display.width - FruitItem.getWidth() * self.xCount - (self.yCount - 1) * self.fruitGap) / 2
    self.matrixLBY = (display.height - FruitItem.getWidth() * self.yCount - (self.xCount - 1) * self.fruitGap) / 2 - 30

    self:addNodeEventListener(cc.NODE_EVENT,function(event)
        if event.name == "enterTransitionFinish" then
            self:initMartrix()
        end
    end)

    self:initUI()
    audio.playMusic("music/mainbg.mp3",true)
end

function PlayScene:initUI()
    display.newSprite("playBG.png")
        :align(display.CENTER,display.cx,display.cy)
        :addTo(self)
    display.newSprite("#high_score.png")
        :align(display.LEFT_CENTER,display.left + 15,display.top - 30)
        :addTo(self)
    display.newSprite("#highscore_part.png")
        :align(display.LEFT_CENTER,display.cx + 10,display.top - 26)
        :addTo(self)
    self.highScoreLabel = cc.ui.UILabel.new({UILabelType = 1,text = tostring(self.highScore),font = "font/earth38.fnt"})
        :align(display.CENTER,display.cx + 105,display.top - 24)
        :addTo(self)
    -- 声音
    display.newSprite("#sound.png")
        :align(display.CENTER, display.right - 60, display.top - 30)
        :addTo(self)

    -- stage
    display.newSprite("#stage.png")
        :align(display.LEFT_CENTER, display.left + 15, display.top - 80)
        :addTo(self)

    display.newSprite("#stage_part.png")
        :align(display.LEFT_CENTER, display.left + 170, display.top - 80)
        :addTo(self)

    self.highStageLabel = cc.ui.UILabel.new({UILabelType = 1, text = tostring(self.stage), font = "font/earth32.fnt"})
        :align(display.CENTER, display.left + 214, display.top - 78)
        :addTo(self)
    
    -- target
    display.newSprite("#tarcet.png")
        :align(display.LEFT_CENTER, display.cx - 50, display.top - 80)
        :addTo(self)

    display.newSprite("#tarcet_part.png")
        :align(display.LEFT_CENTER, display.cx + 130, display.top - 78)
        :addTo(self)

    self.highTargetLabel = cc.ui.UILabel.new({UILabelType = 1, text = tostring(self.target), font = "font/earth32.fnt"})
        :align(display.CENTER, display.cx + 195, display.top - 76)
        :addTo(self)

    -- current sorce
    display.newSprite("#score_now.png")
        :align(display.CENTER, display.cx, display.top - 150)
        :addTo(self)

    self.curScoreLabel = cc.ui.UILabel.new({UILabelType = 1, text = tostring(self.curScore), font = "font/earth48.fnt"})
        :align(display.CENTER, display.cx, display.top - 150)
        :addTo(self)
    --选中水果分数
    self.activeScoreLabel = display.newTTFLabel({text = "",size = 30})
        :pos(display.width / 2,120)
        :addTo(self)
    self.activeScoreLabel:setColor(display.COLOR_WHITE)
    --进度条
    local sliderImages = {
        bar = "#The_time_axis_Tunnel.png",
        button = "#The_time_axis_Trolley.png",
    }
    self.sliderBar = cc.ui.UISlider.new(display.LEFT_TO_RIGHT,sliderImages,{scale9 = false})
        --设置滑动条大小
        :setSliderSize(display.width,125)
        --设置滑动控件的取值
        :setSliderValue(0)
        --指定对齐方式和坐标
        :align(display.LEFT_BOTTOM,0,0)
        :addTo(self)
    self.sliderBar:setTouchEnabled(false)
end

function PlayScene:initMartrix()
    --创建空矩阵
    self.matrix = {}
    --高亮水果
    self.actives = {}
    for y = 1,self.yCount do
        for x = 1,self.xCount do
            -- if 1 == y and 2 == x then
            --     --确保有可消除的水果
            --     self:createAndDropFruit(x,y,self.matrix[1].fruitIdex)
            -- else
                self:createAndDropFruit(x,y)
            --end
        end
    end
end

function PlayScene:createAndDropFruit(x,y,fruitIdex)
    local newFruit = FruitItem.new(x,y,fruitIdex)
    local endPosition = self:positionOfFruit(x,y)
    local startPosition = cc.p(endPosition.x,endPosition.y + display.height / 2)
    newFruit:setPosition(startPosition)
    local speed = startPosition.y / (2 * display.height)
    newFruit:runAction(cc.MoveTo:create(speed,endPosition))
    self.matrix[(y - 1) * self.xCount + x] = newFruit
    self:addChild(newFruit)

    newFruit:setTouchEnabled(true)
    newFruit:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
        if event.name == "ended" then
            if newFruit.isActive then
                local musicIndex = #self.actives
                if musicIndex < 2 then
                    musicIndex = 2
                end
                if musicIndex > 9 then
                    musicIndex = 9
                end
                local tmpStr = string.format("music/broken%d.mp3",musicIndex)
                audio.playSound(tmpStr)
                self:removeActivedFruits()
                self:dropFruits()
                self:checkNextStage()
            else
                self:inactive()
                self:activeNeighbor(newFruit)
                self:showActiveScore()
                --高亮音效
                audio.playSound("music/itemSelect.mp3")
            end
        end
        if event.name == "began" then
            return true
        end
    end)
end

function PlayScene:positionOfFruit(x,y)
    local px = self.matrixLBX + (FruitItem.getWidth() + self.fruitGap) * (x - 1) + FruitItem.getWidth() / 2
    local py = self.matrixLBY + (FruitItem.getWidth() + self.fruitGap) * (y - 1) + FruitItem.getWidth() / 2
    return cc.p(px,py)
end

function PlayScene:inactive()
    for _,fruit in pairs(self.actives) do
        if fruit then
            fruit:setActive(false)
        end
    end
    self.actives = {}
end

function PlayScene:activeNeighbor(fruit)
    --高亮fruit
    if false == fruit.isActive then
        fruit:setActive(true)
        table.insert(self.actives,fruit)
    end
    --检查fruit左边的水果
    if fruit.x - 1 >= 1 then
        local leftNeighbor = self.matrix[(fruit.y - 1) * self.xCount + fruit.x - 1]
        if leftNeighbor.isActive == false and leftNeighbor.fruitIdex == fruit.fruitIdex then
            leftNeighbor:setActive(true)
            table.insert(self.actives,leftNeighbor)
            self:activeNeighbor(leftNeighbor)
        end
    end
    --检查fruit右边的水果
    if fruit.x + 1 <=self.xCount then
        local leftNeighbor = self.matrix[(fruit.y - 1) * self.xCount + fruit.x + 1]
        if leftNeighbor.isActive == false and leftNeighbor.fruitIdex == fruit.fruitIdex then
            leftNeighbor:setActive(true)
            table.insert(self.actives,leftNeighbor)
            self:activeNeighbor(leftNeighbor)
        end
    end
    --检查fruit上边的水果
    if fruit.y + 1 <=self.yCount then
        local leftNeighbor = self.matrix[fruit.y * self.xCount + fruit.x]
        if leftNeighbor.isActive == false and leftNeighbor.fruitIdex == fruit.fruitIdex then
            leftNeighbor:setActive(true)
            table.insert(self.actives,leftNeighbor)
            self:activeNeighbor(leftNeighbor)
        end
    end
    --检查fruit下边的水果
    if fruit.y - 1 >= 1 then
        local leftNeighbor = self.matrix[(fruit.y - 2)* self.xCount + fruit.x]
        if leftNeighbor.isActive == false and leftNeighbor.fruitIdex == fruit.fruitIdex then
            leftNeighbor:setActive(true)
            table.insert(self.actives,leftNeighbor)
            self:activeNeighbor(leftNeighbor)
        end
    end
end

function PlayScene:showActiveScore()
    --只有一个高亮，取消高亮并返回
    if 1 == #self.actives then
        self:inactive()
        self.activeScoreLabel:setString("")
        self.activeScore = 0
        return
    end
    --水果分数依次为5、15、25、35、...，求它们的和
    self.activeScore = (self.scoreStart * 2 + self.scoreStep * (#self.actives - 1) * #self.actives) / 2
    self.activeScoreLabel:setString(string.format("%d连消，得分%d",#self.actives,self.activeScore))
end

function PlayScene:removeActivedFruits()
    local fruitScore = self.scoreStart
    for _,fruit in pairs(self.actives) do
        if fruit then
            --从矩阵中移除
            self.matrix[(fruit.y - 1) * self.xCount + fruit.x] = nil
            local time = 0.3
            --爆炸圈
            local circleSprite = display.newSprite("circle.png")
                :pos(fruit:getPosition())
                :addTo(self)
            circleSprite:setScale(0)
            circleSprite:runAction(cc.Sequence:create(cc.ScaleTo:create(time,1),cc.CallFunc:create(function()
                    circleSprite:removeFromParent()
                end)))
            --爆炸碎片
            local emitter = cc.ParticleSystemQuad:create("stars.plist")
            emitter:setPosition(fruit:getPosition())
            local batch = cc.ParticleBatchNode:createWithTexture(emitter:getTexture())
            batch:addChild(emitter)
            self:addChild(batch)
            --分数特效
            self:scorePopupEffect(fruitScore,fruit:getPosition())
            fruitScore = fruitScore + self.scoreStep
            fruit:removeFromParent()
        end
    end
    --清空高亮数组
    self.actives = {}
    --更新当前得分
    self.curScore = self.curScore + self.activeScore
    self.curScoreLabel:setString(tostring(self.curScore))
    --清空高亮水果分数统计
    self.activeScoreLabel:setString("")
    self.activeScore = 0
    --更新进度条
    local sliderValue = self.curScore / self.target * 100
    if sliderValue > 100 then
        sliderValue = 100
    end
    self.sliderBar:setSliderValue(sliderValue)
end

function PlayScene:dropFruits()
    local emptyInfo = {}
    --1.掉落已存在的水果
    --一列一列的处理
    for x = 1,self.xCount do
        local removeFruits = 0
        local newY = 0
        for y = 1,self.yCount do
            local temp = self.matrix[(y - 1) * self.xCount + x]
            if temp == nil then
                removeFruits = removeFruits + 1
            else
                if removeFruits > 0 then
                    newY = y - removeFruits
                    self.matrix[(newY - 1) * self.xCount + x] = temp
                    temp.y = newY
                    self.matrix[(y - 1) * self.xCount + x] = nil

                    local endPosition = self:positionOfFruit(x,newY)
                    local speed = (temp:getPositionY() - endPosition.y)/display.height
                    temp:stopAllActions()
                    temp:runAction(cc.MoveTo:create(speed,endPosition))
                end
            end
        end
        --记录本列最终空缺数
        emptyInfo[x] = removeFruits
    end
    --掉落新水果补齐空缺数
    for x = 1,self.xCount do
        for y = self.yCount - emptyInfo[x] + 1,self.yCount do
            self:createAndDropFruit(x,y)
        end
    end
end

function PlayScene:scorePopupEffect(score, px, py)
    local labelScore = cc.ui.UILabel.new({UILabelType = 1, text = tostring(score), font = "font/earth32.fnt"})

    local move = cc.MoveBy:create(0.8, cc.p(0, 80))
    local fadeOut = cc.FadeOut:create(0.8)
    local action = transition.sequence({
        cc.Spawn:create(move,fadeOut),
        -- 动画结束移除 Label
        cc.CallFunc:create(function() labelScore:removeFromParent() end)
    })

    labelScore:pos(px, py)
        :addTo(self)
        :runAction(action)
end

function PlayScene:checkNextStage()
    if self.curScore < self.target then
        return
    end
    --通关音效
    audio.playSound("music/wow.mp3")
    --resultLayer半透明展示信息
    local resultLayer = display.newColorLayer(cc.c4b(0,0,0,150))
    resultLayer:addTo(self)
    --吞噬事件
    resultLayer:setTouchEnabled(true)
    resultLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
        if event.name == "began" then
            return true
        end
    end)
    --更新数据
    if self.curScore >= self.highScore then
        self.highScore = self.curScore
    end
    self.stage = self.stage + 1
    self.target = self.stage * 200
    --存储到文件
    cc.UserDefault:getInstance():setIntegerForKey("HighScore",self.highScore)
    cc.UserDefault:getInstance():setIntegerForKey("Stage",self.stage)
    --通关信息
    display.newTTFLabel({text = string.format("恭喜过关！\n 最高分：%d",self.highScore),size = 60})
        :pos(display.cx,display.cy + 140)
        :addTo(resultLayer)
    --开始按钮
    local startBtnImages = {normal = "#startBtn_N.png",pressed = "#startBtn_S.png"}
    cc.ui.UIPushButton.new(startBtnImages,{scale9 = false})
        :onButtonClicked(function(event)
            --停止背景音乐
            audio.stopMusic()
            local mainScene = import("app.scenes.MainScene"):new()
            display.replaceScene(mainScene,"flipX",0.5)
        end)
        :align(display.CENTER,display.cx,display.cy - 80)
        :addTo(resultLayer)
end

function PlayScene:onEnter()
end

function PlayScene:onExit()
end

return PlayScene