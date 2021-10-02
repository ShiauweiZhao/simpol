classdef XML
    %XML Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        function doc = str2dom(s, varargin)
            
            p = inputParser;
            p.CaseSensitive = false;
            p.addParameter('fragment', false, @islogical);
            p.parse(varargin{:});
            bFragment = p.Results.fragment;            
            
            
            import javax.xml.parsers.DocumentBuilder;
            import javax.xml.parsers.DocumentBuilderFactory;       
            
            if bFragment
                s = ['<root-fragment>' s '</root-fragment>'];
            end
            
            docFactory = DocumentBuilderFactory.newInstance();
            docBuilder = docFactory.newDocumentBuilder();

            is = org.xml.sax.InputSource(java.io.StringReader(s));
            
            doc = docBuilder.parse(is);
        end
        
        function s = dom2str(dom, varargin)
            
            p = inputParser;
            p.CaseSensitive = false;
            p.addParameter('omitDeclaration', false, @islogical);
            p.addParameter('fragment', false, @islogical);
            p.parse(varargin{:});
            bOmitDeclaration = p.Results.omitDeclaration;
            bFragment = p.Results.fragment;
            
            import javax.xml.transform.Transformer;
            import javax.xml.transform.TransformerException;
            import javax.xml.transform.TransformerFactory;
            import javax.xml.transform.dom.DOMSource;
            import javax.xml.transform.stream.StreamResult;
            import javax.xml.transform.OutputKeys;

            tf = TransformerFactory.newInstance();
            transformer = tf.newTransformer();
            if bOmitDeclaration || bFragment
                transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, 'yes');
            end
            
            writer = java.io.StringWriter();
            
            transformer.transform(DOMSource(dom),...
                StreamResult(writer));
            
            s = char(writer.getBuffer.toString());
            
            if bFragment
                s = string(s);
                s = s.erase('<root-fragment>');
                s = s.erase('</root-fragment>');
                s = char(s);
            end
        end        
    end
    
end

