var gRequest = null;

function createRequest() {
    var req = null;
   
    try {
        req = new XMLHttpRequest();
    } catch (trymicrosoft) {
        try {
            req = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (othermicrosoft) {
            try {
                req = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (failed) {
                req = null;
            }
        }
    }

    return(req);
}

function DisplayPage()
{
    gRequest = createRequest();
    if (gRequest==null)
    {
        alert ("Browser does not support HTTP Request");
        return;
    } 
    var pdb   = document.getElementById("pdb").value;
    var chain = document.getElementById("chain").value;
    var url="./intpred.cgi?pdb="+pdb+"&amp;chain="+chain;

    document.getElementById("throbber").style.display = 'inline';
    document.getElementById("submit").disabled        = true;
    document.getElementById("pdb").disabled           = true;
    document.getElementById("chain").disabled         = true;

    gRequest.open("GET",url,true);

    gRequest.onreadystatechange=updatePage;
    gRequest.send(null);
}

function updatePage() 
{ 
    if (gRequest.readyState==4 || gRequest.readyState=="complete")
    { 
        document.getElementById("results").innerHTML      = gRequest.responseText;
        document.getElementById("throbber").style.display = 'none';
        document.getElementById("submit").disabled        = false;
        document.getElementById("pdb").disabled           = false;
        document.getElementById("chain").disabled         = false;
    } 
} 
