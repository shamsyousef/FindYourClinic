namespace FindYourClinic.Domain.Exceptions;

public class DomainException : Exception
{
    public DomainException(string message) : base(message)
    {
    }
}

public class NotFoundException : DomainException
{
    public NotFoundException(string message) : base(message)
    {
    }
}

public class ForbiddenException : DomainException
{
    public ForbiddenException(string message) : base(message)
    {
    }
}

public class UnauthorizedException : DomainException
{
    public UnauthorizedException(string message) : base(message)
    {
    }
}

public class BadRequestException : DomainException
{
    public BadRequestException(string message) : base(message)
    {
    }
}

public class ServiceUnavailableException : DomainException
{
    public ServiceUnavailableException(string message) : base(message)
    {
    }
}

public class CloudinaryException : DomainException
{
    public CloudinaryException(string message) : base(message)
    {
    }
}