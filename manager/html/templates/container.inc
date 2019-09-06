	<div class="col-md-4">
	  <div class="card mb-4 box-shadow">
	    <img class="card-img-top" src="/images/{{type}}.png" alt="{{type}}"/>
	    <div class="card-body">
	      <p class="card-text">{{name}}</p>
	      <div class="d-flex justify-content-between align-items-center">
	      <div class="btn-group">
	        <a href="/connect/{{id}}/" class="btn btn-sm btn-outline-secondary">Connect</a>
                <button type="button" class="btn btn-sm btn-outline-secondary" data-toggle="modal" data-target="#stopWorkspace" data-id="{{id}}" data-name="{{name}}">Stop</button>
	      </div>
	      <small class="text-muted">{{ellapsed}}</small>
	    </div>
	  </div>
	</div>
      </div>
