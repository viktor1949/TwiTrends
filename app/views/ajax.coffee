load_table = (table) ->
	($ "#time a").removeClass("active")
	$("##{table}").addClass("active")
	$.getJSON "/top.json?mode=#{table}", (data) ->
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

$ ->
	load_table(window.location.hash[1..-1])

	($ "#time a").live 'click', (e) ->
		load_table($(this).attr('id'))

	
