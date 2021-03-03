# Disclaimer: this may not be the most readable source code you've ever seen.

source = File.read('bel.bel.lisp').split("\n")
guide = File.read('guide.md').split("\n")

guide_stuff = []
guide_filtered = guide.select.with_index do |line, i|
	is_magical = line.start_with? '!!'
	if is_magical
		guide_stuff << [i - guide_stuff.length, line.slice(2..(-1))]
	end
	!is_magical
end

source_stuff = {}
source.each.with_index do |line, i|
	if /^\((\S+ (\S+))/.match(line)
		source_stuff[$1] = i
		source_stuff[$2] = i
	end
end

chunk_lines = [[0, 0, false]]
guide_stuff.each do |thing|
	guide_line_num, id = thing
	source_line_num = source_stuff[id]
	throw "id not available: #{id}" if !source_line_num
	chunk_lines << [guide_line_num, source_line_num]
end
chunk_lines << [guide.length - 1, source.length - 1]

chunks = chunk_lines.each_cons(2).to_a.map do |pair|
	if pair[1][0] < pair[0][0] || pair[1][1] < pair[0][1]
		raise "not in order: #{pair[0][1]}, #{pair[1][1]}"
	end
	[
		guide_filtered.slice(pair[0][0]...pair[1][0]).join("\n"),
		         source.slice(pair[0][1]...pair[1][1]).join("\n")
	]
end

##########

html = <<-HTML
<!DOCTYPE html>
<html lang="en">
<title>Bel</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
	html, body {
		margin: 0%;
	}
	.container {
		display: flex;
		width: 100%;
	}
	.guide {
		/*background-color: white;*/
		width: 50%;
		padding: 0 2rem;
	}
	.source {
		/*background-color: rgb(45, 45, 45);*/
		width: 50%;
		padding: 0 1rem;
		position: -webkit-sticky;
		position: sticky;
		top: 0;
		align-self: flex-start;
	}
	.source pre {
		max-height: 95vh;
	}

	.container:first-child {
		justify-content: center;
	}
	.container:first-child .guide {
		width: min(100%, 63rem);
	}
	@media screen and (min-width: 900px) {
		.container:first-child .guide {
			padding: 1rem 5rem;
		}
	}
	.container:first-child .source {
		display: none;
	}

	@media screen and (max-width: 900px) {
		.container {
			flex-direction: column-reverse;
		}
		.guide {
			width: 100%;
		}
		.source {
			width: 100%;
			background-color: rgb(2, 2, 70);
		}
		.source pre {
			max-height: 30vh;
		}
	}

	* {
		/* for performance */
		contain: content;
	}

	/* Basic.CSS https://github.com/vladocar/Basic.css */
	*{box-sizing:border-box}:root{--sans:1em/1.6 system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Oxygen,Ubuntu,Cantarell,Droid Sans,Helvetica Neue,Fira Sans,sans-serif;--mono:SFMono-Regular,Consolas,'Liberation Mono',Menlo,Courier,'Courier New',monospace;--c1:#0074d9;--c2:#eee;--c3:#fff;--c4:#000;--c5:#fff;--m1:8px;--rc:8px}@media (prefers-color-scheme:dark){:root{--c2:#333;--c3:#1e1f20;--c4:#fff}}html{-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}body{margin:0;font:var(--sans);font-weight:400;font-style:normal;text-rendering:optimizeLegibility;-webkit-font-smoothing:antialiased;background-color:var(--c3);color:var(--c4)}iframe,img{border:none;max-width:100%}a{color:var(--c1);text-decoration:none}a:hover{color:var(--c1);text-decoration:underline}pre{font:1em/1.6 var(--mono);background:var(--c2);padding:1em;overflow:auto}code{font:1em/1.6 var(--mono)}blockquote{border-left:5px solid var(--c2);padding:1em 1.5em;margin:0}hr{border:0;border-bottom:1px solid var(--c4)}h1,h2,h3,h4,h5,h6{margin:.6em 0;font-weight:400}h1{font-size:2.625em;line-height:1.2}h2{font-size:1.625em;line-height:1.2}h3{font-size:1.3125em;line-height:1.24}h4{font-size:1.1875em;line-height:1.23}h5,h6{font-size:1em;font-weight:700}table{border-collapse:collapse;border-spacing:0;margin:1em 0}td,th{text-align:left;vertical-align:top;border:1px solid;padding:.4em}tfoot,thead{background:var(--c2)}button,code,img,input,pre,select,textarea{border-radius:var(--rc)}input,select,textarea{font-size:1em;color:var(--c4);background:var(--c2);border:0;padding:.6em}button,input[type=button],input[type=reset],input[type=submit]{-webkit-appearance:none;font-size:1em;display:inline-block;color:var(--c5);background:var(--c1);border:0;margin:4px;padding:.6em;cursor:pointer;text-align:center}button:focus,button:hover,input:hover,select:hover,textarea:hover{opacity:.8}section{display:flex;flex-flow:row wrap}[style*="--c:"],article,aside,section>section{flex:var(--c,1);margin:var(--m1)}article{background:var(--c2);border-radius:var(--rc);padding:1em;box-shadow:0 1px 0 rgba(0,0,0,.3)}[style*="--c:"]:first-child,article:first-child,section>section:first-child{margin-left:0}[style*="--c:"]:last-child, section>section:last-child, article:last-child {margin-right:0}
</style>

<main>
HTML

require 'kramdown'

for chunk in chunks
	guide_chunk, source_chunk = chunk
	guide_chunk.gsub! "```", "~~~"
	guide_html = Kramdown::Document.new(guide_chunk).to_html
	source_html = Kramdown::Document.new("~~~\n"+source_chunk+"\n~~~").to_html
	html += <<-HTML
		<div class="container">
			<div class="guide">#{guide_html}</div>
			<div class="source">#{source_html}</div>
		</div>
	HTML
end

html += "</main></html>"

File.open('index.html', 'w') { |file| file.write html }
