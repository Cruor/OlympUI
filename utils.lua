local uiu = {}

function uiu.nop()
end


uiu.dataRoots = {}


uiu.imageCache = {}
function uiu.image(path)
    local root = ""

    local split = path:find(":")
    if split then
        if split == 1 then
            path = path:sub(2)
        else
            root = path:sub(1, split - 1)
            path = path:sub(split + 1)
        end
    end

    root = root or ""
    local mappedRoot = uiu.dataRoots[root]
    if mappedRoot then
        path = mappedRoot .. "/" .. path

    elseif #root > 0 then
        path = root .. "/data/" .. path

    else
        path = "data/" .. path
    end

    path = path .. ".png"

    local cache = uiu.imageCache
    local img = cache[path]
    if img then
        return img
    end

    img = love.graphics.newImage(path)
    cache[path] = img
    return img
end


function uiu.isCallback(cb)
    if type(cb) == "function" then
        return true
    end

    local mt = getmetatable(cb)
    return mt and mt.__call and true
end


function uiu.round(x)
    return x + 0.5 - (x + 0.5) % 1
end
math.round = math.round or uiu.round


function uiu.sign(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end
math.sign = math.siggn or uiu.sign


function uiu.listRange(from, to, step)
    local output = {}
    local count = 1
    for i = from, to, (step or 1) do
        output[count] = i
        count = count + 1
    end
    return output
end


function uiu.map(input, fn)
    local output = {}
    for k, v in pairs(input) do
        output[k] = fn(v)
    end
    return output
end


function uiu.join(list, splitter)
    local output = ""
    if #list == 0 then
        return output
    end
    for i = 1, #list - 1 do
        output = output .. tostring(list[i]) .. splitter
    end
    for i = #list, #list do
        output = output .. tostring(list[i])
    end
    return output
end


function uiu.concat(...)
    return uiu.join({ ... }, "")
end


function uiu.magic(fn, ...)
    local magic = uiu.magic
    local mask = { ... }

    return function(...)
        local input = { ... }
        local args = {}

        local ii = 1

        for i = 1, #mask do
            local arg = mask[i]
            if arg == magic then
                arg = input[ii]
                ii = ii + 1
            end
            args[i] = arg
        end

        local offs = #args + 1
        for i = ii, #input do
            args[i - ii + offs] = input[i]
        end

        return fn(table.unpack(args))
    end
end


function uiu.hook(target, nameOrMap, cb)
    if type(nameOrMap) ~= "string" then
        for name, cb in pairs(nameOrMap) do
            uiu.hook(target, name, cb)
        end
        return
    end

    local name = nameOrMap
    local orig = target[name] or uiu.nop
    target[name] = function(...)
        return cb(orig, ...)
    end
end


function uiu.fillWidth(el)
    uiu.hook(el, {
        layoutLazy = function(orig, self)
            -- Required to allow the container to shrink again.
            orig(self)
            self.width = 0
        end,
    
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(orig, self)
            local width = self.parent.innerWidth
            self.width = width
            self.innerWidth = width - self.style.padding * 2
            orig(self)
        end
    })
end

function uiu.fillWidthExcept(leftover)
    return function(el)
        uiu.hook(el, {
            layoutLazy = function(orig, self)
                -- Required to allow the container to shrink again.
                orig(self)
                self.width = 0
            end,
        
            layoutLateLazy = function(orig, self)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
            end,
        
            layoutLate = function(orig, self)
                local width = self.parent.innerWidth - leftover
                self.width = width
                self.innerWidth = width - self.style.padding * 2
                orig(self)
            end
        })
    end
end


function uiu.fillHeight(el)
    uiu.hook(el, {
        layoutLazy = function(orig, self)
            -- Required to allow the container to shrink again.
            orig(self)
            self.height = 0
        end,
    
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(orig, self)
            local Height = self.parent.innerHeight
            self.height = Height
            self.innerHeight = Height - self.style.padding * 2
            orig(self)
        end
    })
end

function uiu.fillHeightExcept(leftover)
    return function(el)
        uiu.hook(el, {
            layoutLazy = function(orig, self)
                -- Required to allow the container to shrink again.
                orig(self)
                self.height = 0
            end,
        
            layoutLateLazy = function(orig, self)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
            end,
        
            layoutLate = function(orig, self)
                local Height = self.parent.innerHeight - leftover
                self.height = Height
                self.innerHeight = Height - self.style.padding * 2
                orig(self)
            end
        })
    end
end


function uiu.fill(el)
    uiu.hook(el, {
        layoutLazy = function(orig, self)
            -- Required to allow the container to shrink again.
            orig(self)
            self.width = 0
            self.height = 0
        end,
    
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(orig, self)
            local width = self.parent.innerWidth
            local height = self.parent.innerHeight
            self.width = width
            self.height = height
            self.innerWidth = width - self.style.padding * 2
            self.innerHeight = height - self.style.padding * 2
            orig(self)
        end
    })
end

function uiu.fillExcept(leftoverX, leftoverY)
    return function(el)
        uiu.hook(el, {
            layoutLazy = function(orig, self)
                -- Required to allow the container to shrink again.
                orig(self)
                self.width = 0
                self.height = 0
            end,
        
            layoutLateLazy = function(orig, self)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
            end,
        
            layoutLate = function(orig, self)
                local width = self.parent.innerWidth - leftoverX
                local height = self.parent.innerHeight - leftoverY
                self.width = width
                self.height = height
                self.innerWidth = width - self.style.padding * 2
                self.innerHeight = height - self.style.padding * 2
                orig(self)
            end
        })
    end
end


function uiu.rightbound(el)
    uiu.hook(el, {
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            self:layoutLate()
        end,
    
        layoutLate = function(orig, self)
            local parent = self.parent
            self.realX = parent.innerWidth - self.width
            orig(self)
        end
    })
end


table.pack = table.pack or function(...)
    return { ... }
end
table.unpack = table.unpack or _G.unpack


return uiu
