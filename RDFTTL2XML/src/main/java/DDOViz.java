import org.apache.jena.rdf.model.Model;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.riot.RDFFormat;
import org.basex.core.*;
import org.basex.core.cmd.XQuery;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;

public class DDOViz {

    static Context context = new Context();

    public static void main(String[] args) throws IOException {
        Model model = RDFDataMgr.loadModel("example.ttl");
        FileOutputStream out = new FileOutputStream("running.rdf");
        RDFDataMgr.write(out, model, RDFFormat.RDFXML_PLAIN);
        String query = Files.readString(Paths.get("ddoviz.xq"));
        String result = new XQuery(query).execute(context);
        out = new FileOutputStream("output.xml");
        out.write(result.getBytes());
    }
}
