#include "roundinfo.h"

RoundInfo::RoundInfo(uint end, const QString &name,
                     const QString &nextName, int playing) :
    QObject(),
    end_(end),
    name_(name),
    nextName_(nextName),
    playing_(playing)
{
}

uint RoundInfo::end() const
{
    return end_;
}

const QString &RoundInfo::name() const
{
    return name_;
}

const QString &RoundInfo::nextName() const
{
    return nextName_;
}

int RoundInfo::playing() const
{
    return playing_;
}

void RoundInfo::setEnd(const uint &v)
{
    end_ = v;
}

void RoundInfo::setName(const QString &v)
{
    name_ = v;
}

void RoundInfo::setNextName(const QString &v)
{
    nextName_ = v;
}

void RoundInfo::setPlaying(int v)
{
    playing_ = v;
}

