module ApplicationHelper
  def flash_bootstrap_class(type)
    { "notice" => "success", "alert" => "danger", "info" => "info", "warning" => "warning" }
      .fetch(type.to_s, "secondary")
  end

  def render_agenda_markdown(markdown_text)
    renderer = Redcarpet::Render::HTML.new(safe_links_only: true, hard_wrap: true)
    md = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true, tables: true)
    raw md.render(markdown_text.to_s)
  end
end
