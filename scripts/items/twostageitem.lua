TwoStageItem = CustomItem:extend()

function TwoStageItem:init(name, code1, code2, img1, img2)
    self:createItem(name)

    code1 = string.gsub(code1, " ", "")
    self.codes1 = {}
    if string.find(code1, ",") ~= nil then
        for str in string.gmatch(code1, "([^,]+)") do
            table.insert(self.codes1, str)
        end
    else table.insert(self.codes1, code1)
    end

    code2 = string.gsub(code2, " ", "")
    self.codes2 = {}
    if string.find(code2, ",") ~= nil then
        for str in string.gmatch(code2, "([^,]+)") do
            table.insert(self.codes2, str)
        end
    else table.insert(self.codes2, code2)
    end

    self.img1 = ImageReference:FromPackRelativePath(img1)
    self.img2 = ImageReference:FromPackRelativePath(img2)

    self:setState(0)
    self:performUpdate()
end

function TwoStageItem:getState()
    return self:getProperty("state")
end

function TwoStageItem:setState(state)
    self:setProperty("state", state)
end

function TwoStageItem:onLeftClick()
    self:setState((self:getState() + 1) % 2)
end

function TwoStageItem:onRightClick()
    self:setState((self:getState() - 1) % 2)
end

function TwoStageItem:performUpdate()
    self.ItemInstance.Icon = self:getState() == 0 and self.img1 or self.img2

    OBJ_MISSILE:UpdateBadgeAndIcon()
    OBJ_SUPER:UpdateBadgeAndIcon()
    OBJ_POWER:UpdateBadgeAndIcon()
end

function TwoStageItem:canProvideCode(code)
    for i,c in ipairs(self.codes1) do
        if (code == c or code == string.lower(c)) then
            return true
        end
    end
    for i,c in ipairs(self.codes2) do
        if (code == c or code == string.lower(c)) then
            return true
        end
    end
    return false
end

function TwoStageItem:providesCode(code)
    for i,c in ipairs(self.codes1) do
        if (code == c or code == string.lower(c)) and self:getState() == 0 then
            return 1
        end
    end
    for i,c in ipairs(self.codes2) do
        if (code == c or code == string.lower(c)) and self:getState() > 0 then
            return 1
        end
    end
    return 0
end

function TwoStageItem:save()
    local data = {}
    data["state"] = self:getState()
    return data
end

function TwoStageItem:load(data)
    if data["state"] ~= nil then
        self:setState(data["state"])
    end
    return true
end

function TwoStageItem:propertyChanged(key, value)
    if key == "state" then
        self:performUpdate()
    end
end