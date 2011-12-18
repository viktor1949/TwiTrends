$ ->
	($ "#time a").live 'click', (e) ->
		all = ($ "#time a")
		all.removeClass("active")
		$(this).addClass("active")
		$.getJSON "/top.json?mode=#{$(this).attr('id')}", (data) ->
			$('#trends').find("tr").remove()
			i = 0
			for d in data
				i += 1
				$('#trends > tbody:last')
				.append("<tr>
					<td class='trends-count'>#{i}</td>
				    <td class='trends-hashtag'> 
					<a href='http://twitwave.ru/wave/index/#{encodeURIComponent(d.hashtag)}' target='_blank'>#{d.hashtag}</a>
					<sup>#{d.count}</sup>
					</td>
					</tr>"
				)  
