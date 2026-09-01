```{=html}
<table class="quarto-listing-table table">
<thead>
<tr>
<th>Cours</th>
<th>Date</th>
<th>Contenu</th>
<th>Résumé</th>
</tr>
</thead>
<tbody>
<% for (const item of items) { %>

<tr <%= metadataAttrs(item) %>>
```

<td><a href="<%- item.path %>" class="no-external">Cours&nbsp;<%= item["week-id"] %></a></td>
<td>
<% const firstClassDate = item["first-class-date"]; %>
<% const weekId = Number(item["week-id"]); %>
<% const courseDate = firstClassDate && Number.isFinite(weekId)
  ? new Date(`${firstClassDate}T12:00:00`)
  : null; %>
<% if (courseDate) { courseDate.setDate(courseDate.getDate() + ((weekId - 1) * 7)); } %>
<% if (courseDate) { %><time class="course-listing-date" datetime="<%= courseDate.toISOString().slice(0, 10) %>"><%= courseDate.toISOString().slice(0, 10) %></time><% } %>
</td>
<td>
<% if (item.chapitres && item.chapitres.length) { %>
<div class="course-listing-chapters">
<% item.chapitres.forEach((chapitre) => {
  const path = String(chapitre.path || "").replace(/\/$/, "");
  const match = path.match(/\/(\d+)-/);
  const number = match ? Number(match[1]) : "";
  const title = chapitre.title || "";
%>
<div class="course-listing-chapter">
<span class="course-listing-chapter-title">Chapitre&nbsp;<%= number %> — <%= title %></span>
<span class="course-listing-chapter-links"><a href="<%- path %>/diapos.html" class="no-external">Notes</a><a href="<%- path %>/exercices.html" class="no-external">Exercices</a></span>
</div>
<% }); %>
</div>
<% } else { %>
<span class="course-listing-empty">Examen&nbsp;1</span>
<% } %>
</td>
<td><%= item.description || "" %></td>

```{=html}

</tr>
<% } %>
</tbody>
</table>
```
