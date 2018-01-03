
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    --加载精灵帧
    display.addSpriteFrames("fruit.plist","fruit.png")
    --背景图片
    display.newSprite("mainBG.png")
    	:pos(display.cx,display.cy)
    	:addTo(self)
    local startBtnImages = {
    	normal = "#startBtn_N.png",
    	pressed = "#startBtn_S.png"
	}
	--开始按钮
	cc.ui.UIPushButton.new(startBtnImages,{scale = false})
		:onButtonClicked(function(event)
            audio.playSound("music/btnStart.mp3")
			local playScene = import("app.scenes.PlayScene").new()
    		display.replaceScene(playScene,"turnOffTiles",0.5)
		end)
		:align(display.CENTER,display.cx,display.cy - 80)
		:addTo(self)
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

return MainScene
