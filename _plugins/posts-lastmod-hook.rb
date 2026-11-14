Jekyll::Hooks.register :posts, :pre_render do |post|
  modification_time = File.mtime(post.path)
  post.data['last_modified_at'] = modification_time
end
