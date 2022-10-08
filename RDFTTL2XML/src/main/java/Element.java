import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;
import java.io.Serializable;

@XmlRootElement(name = "class")
@XmlAccessorType(XmlAccessType.PROPERTY)
public class Element implements Serializable {

    private static final long serialVersionUID = 1L;

    @XmlAttribute
    private Integer contextDepth;
    @XmlAttribute
    private Integer contextLevel;
    @XmlAttribute
    private Integer parentLevel;
    @XmlAttribute
    private Integer contextHeight;
    @XmlAttribute
    private Integer contextWidth;
    @XmlAttribute
    private String description;
    @XmlAttribute
    private String ctx;
    @XmlAttribute
    private String parent;
    @XmlAttribute
    private String preferredSuperclass;

    public Element() {
        super();
    }

    public Element(Integer contextDepth, Integer contextLevel, Integer parentLevel, Integer contextHeight, Integer contextWidth, String description, String ctx, String parent, String preferredSuperclass) {
        this.contextDepth = contextDepth;
        this.contextLevel = contextLevel;
        this.parentLevel = parentLevel;
        this.contextHeight = contextHeight;
        this.contextWidth = contextWidth;
        this.description = description;
        this.ctx = ctx;
        this.parent = parent;
        this.preferredSuperclass = preferredSuperclass;
    }

    public static long getSerialVersionUID() {
        return serialVersionUID;
    }

    public Integer getContextDepth() {
        return contextDepth;
    }

    public Integer getContextLevel() {
        return contextLevel;
    }

    public Integer getParentLevel() {
        return parentLevel;
    }

    public Integer getContextHeight() {
        return contextHeight;
    }

    public Integer getContextWidth() {
        return contextWidth;
    }

    public String getDescription() {
        return description;
    }

    public String getCtx() {
        return ctx;
    }

    public String getParent() {
        return parent;
    }

    public String getPreferredSuperclass() {
        return preferredSuperclass;
    }

    @Override
    public String toString() {
        return "Element{" +
                "contextDepth=" + contextDepth +
                ", contextLevel=" + contextLevel +
                ", parentLevel=" + parentLevel +
                ", contextHeight=" + contextHeight +
                ", contextWidth=" + contextWidth +
                ", description='" + description + '\'' +
                ", ctx='" + ctx + '\'' +
                ", parent='" + parent + '\'' +
                ", preferredSuperclass='" + preferredSuperclass + '\'' +
                '}';
    }
}
