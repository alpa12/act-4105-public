```{=html}
<table class="quarto-listing-table table">
<thead>
<tr>
<th>Chapitre</th>
<th>Titre</th>
<th>Description</th>
<th>Diapositives</th>
<th>Exercices</th>
</tr>
</thead>
<tbody>
<% for (const item of items) { 
  const exercicesPath = item.path || "";
  const diaposPath = String(exercicesPath)
    .replace("exercices.qmd", "diapos.qmd")
    .replace("exercices.html", "diapos.html");
%>
<tr <%= metadataAttrs(item) %>>
<td><%= item.order || "" %></td>
<td><%= item.title || "" %></td>
<td><%= item.description || "" %></td>
<td><a href="<%- diaposPath %>" class="no-external">Diapositives</a></td>
<td><a href="<%- exercicesPath %>" class="no-external">Exercices</a></td>
</tr>
<% } %>
</tbody>
</table>
```
