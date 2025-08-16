json.board_key @board_key

json.stages @stages do |stage|
  json.id stage.id
  json.key stage.key
  json.name stage.name
  json.color stage.color
  json.icon stage.icon
  json.position stage.position
  json.active stage.active
end

json.conversations do
  @conversations_by_stage.each do |stage_key, conversations|
    json.set! stage_key, conversations
  end
end