local ui = require("ui.main")
local uie = require("ui.elements.main")
local uiu = require("ui.utils")


-- Basic panel with children elements.
uie.add("panel", {
    init = function(self, children)
        self.children = children or {}
        self.width = -1
        self.height = -1
        self.minWidth = -1
        self.minHeight = -1
        self.maxWidth = -1
        self.maxHeight = -1
        self.forceWidth = -1
        self.forceHeight = -1
        self.clip = true
    end,

    style = {
        bg = { 0.08, 0.08, 0.08, 0.2 },
        border = { 0, 0, 0, 0 },
        padding = 8,
        radius = 3
    },

    calcSize = function(self, width, height)
        local manualWidth = self.width
        manualWidth = manualWidth ~= -1 and manualWidth or nil
        local manualHeight = self.height
        manualHeight = manualHeight ~= -1 and manualHeight or nil

        local forceWidth
        if self.__autoWidth ~= manualWidth then
            forceWidth = manualWidth or -1
            self.forceWidth = forceWidth
        else
            forceWidth = self.forceWidth or -1
        end

        local forceHeight
        if self.__autoHeight ~= manualHeight then
            forceHeight = manualHeight or -1
            self.forceHeight = forceHeight
        else
            forceHeight = self.forceHeight or -1
        end

        width = forceWidth >= 0 and forceWidth or width or -1
        height = forceHeight >= 0 and forceHeight or height or -1

        if width < 0 and height < 0 then
            local max = math.max
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                width = max(width, c.x + c.width)
                height = max(height, c.y + c.height)
            end

        elseif width < 0 then
            local max = math.max
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                width = max(width, c.x + c.width)
            end

        elseif height < 0 then
            local max = math.max
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                height = max(height, c.y + c.height)
            end
        end

        if self.minWidth >= 0 and width < self.minWidth then
            width = self.minWidth
        end
        if self.maxWidth >= 0 and self.maxWidth < width then
            width = self.maxWidth
        end

        if self.minHeight >= 0 and height < self.minHeight then
            height = self.minHeight
        end
        if self.maxHeight >= 0 and self.maxHeight < height then
            height = self.maxHeight
        end

        self.innerWidth = width
        self.innerHeight = height

        width = width + self.style.padding * 2
        height = height + self.style.padding * 2

        self.__autoWidth = width
        self.__autoHeight = height
        self.width = width
        self.height = height
    end,

    layoutChildren = function(self)
        local padding = self.style.padding
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c:layoutLazy()
            c.realX = c.x + padding
            c.realY = c.y + padding
        end
    end,

    repositionChildren = function(self)
        local padding = self.style.padding
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c.realX = c.x + padding
            c.realY = c.y + padding
        end
    end,

    draw = function(self)
        local x = self.screenX
        local y = self.screenY
        local w = self.width
        local h = self.height

        local radius = self.style.radius
        local bg = self.style.bg
        if bg and #bg ~= 0 and bg[4] ~= 0 then
            love.graphics.setColor(bg)
            love.graphics.rectangle("fill", x, y, w, h, radius, radius)
        end

        if w >= 0 and h >= 0 then
            local sX, sY, sW, sH
            local clip = self.clip -- and not self.cachedCanvas
            if clip then
                sX, sY, sW, sH = love.graphics.getScissor()
                if self.cachedCanvas then
                    local padding = self.cachePadding
                    local scissorX, scissorY = love.graphics.transformPoint(x, y)
                    love.graphics.setScissor(scissorX, scissorY, w + padding * 2, h + padding * 2)
                else
                    local scissorX, scissorY = love.graphics.transformPoint(x, y)
                    love.graphics.intersectScissor(scissorX, scissorY, w, h)
                end
            end

            local children = self.children
            if not self.cacheable then
                for i = 1, #children do
                    local c = children[i]
                    if c.onscreen and c.visible then
                        c:drawLazy()
                    end
                end
            else
                for i = 1, #children do
                    children[i]:drawLazy()
                end
            end

            if clip then
                love.graphics.setScissor(sX, sY, sW, sH)
            end
        end


        local border = self.style.border
        if border and #border ~= 0 and border[4] ~= 0 and border[5] ~= 0 then
            love.graphics.setColor(border)
            love.graphics.setLineWidth(border[5] or 1)
            love.graphics.rectangle("line", x, y, w, h, radius, radius)
        end
    end
})


-- Panel which doesn't display as one by default.
uie.add("group", {
    base = "panel",

    cachePadding = 0,

    style = {
        bg = {},
        border = {},
        padding = 0,
        radius = 0
    },

    init = function(self, ...)
        uie.__panel.init(self, ...)
        self.clip = false
    end
})


-- Basic label.
uie.add("label", {
    cacheable = false,

    style = {
        color = { 1, 1, 1, 1 },
        font = love.graphics.getFont()
    },

    init = function(self, text)
        self.text = text or ""
        self.dynamic = false
        self.wrap = false
    end,

    getText = function(self)
        return self._textStr
    end,

    setText = function(self, value)
        if value == self._textStr then
            return
        end
        self._textStr = value

        if type(value) ~= "userdata" then
            if not self._text then
                self._text = love.graphics.newText(self.style.font, value)
            else
                self._text:set(value)
            end
        else
            self._text = value
        end

        if not self.dynamic and (self.width ~= math.ceil(self._text:getWidth()) or self.height ~= math.ceil(self._text:getHeight())) then
            self:reflow()
        else
            self:repaint()
        end
    end,

    layoutLazy = function(self)
        uie.__default.layoutLazy(self)

        if self.wrap then
            local width, wrapped = self.style.font:getWrap(self._textStr, self.parent.width)
            self.width = width
            self._text:set(uiu.join(wrapped, "\n"))
            self.height = self:calcHeight()
        end
    end,

    calcWidth = function(self)
        return math.ceil(self._text:getWidth())
    end,

    calcHeight = function(self)
        return math.ceil(self._text:getHeight())
    end,

    draw = function(self)
        love.graphics.setColor(self.style.color)
        love.graphics.draw(self._text, self.screenX, self.screenY)
    end
})


-- Basic image.
uie.add("image", {
    cacheable = false,

    style = {
        color = { 1, 1, 1, 1 }
    },

    quad = nil,
    transform = nil,
    drawArgs = nil,

    init = function(self, image)
        if type(image) == "string" then
            self.id = image
            image = uiu.image(image)
        end
        self._image = image
    end,

    calcSize = function(self)
        local image = self._image
        local width, height = image:getWidth(), image:getHeight()

        local transform = self.transform
        if transform then
            width, height = transform:transformPoint(width, height)
        end

        self.width = width
        self.height = height
    end,

    draw = function(self)
        love.graphics.setColor(self.style.color)

        local drawArgs = self.drawArgs
        if drawArgs then
            love.graphics.draw(self._image, table.unpack(drawArgs))

        else
            local transform = self.transform
            local quad = self.quad
            if transform then
                if quad then
                    love.graphics.draw(self._image, quad, transform)
                else

                    love.graphics.draw(self._image, transform)
                end

            else
                if quad then
                    love.graphics.draw(self._image, quad, self.screenX, self.screenY)

                else
                    love.graphics.draw(self._image, self.screenX, self.screenY)
                end
            end
        end
    end
})


return uie
